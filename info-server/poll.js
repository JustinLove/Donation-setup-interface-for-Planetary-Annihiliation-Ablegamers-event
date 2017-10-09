var Redis = require('redis')
var redis = Redis.createClient({
  url: process.env.REDIS_URL,
  // source: https://www.npmjs.com/package/redis
  retry_strategy: function (options) {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      // End reconnecting on a specific error and flush all commands with 
      // a individual error 
      return new Error('The server refused the connection');
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      // End reconnecting after a specific timeout and flush all commands 
      // with a individual error 
      return new Error('Retry time exhausted');
    }
    if (options.attempt > 10) {
      // End reconnecting with built in error 
      return undefined;
    }
    // reconnect after 
    return Math.min(options.attempt * 100, 3000);
  }
})
redis.on('error', function(err) {
  console.log('Redis error', err)
})

var feedName = process.env.FEED

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require
});

var donations = []

var updateMatchesInDonations = function(list) {
  loadGameIds().then(function(games) {
    list.forEach(function(dm) {
      dm.matchMatches(games, '')
    })
  })
}

var loadGameIds = function() {
  return new Promise(function(resolve, reject) {
    redis.smembers('games', function(err, games) {
      if (games) {
        console.log('loaded games', games)
        resolve(games)
      } else {
        reject(err)
      }
    })
  })
}

requirejs(['donation_data/feed', 'donation_data/donation'], function (feed, Donation) {
  var loadDonationHistory = function() {
    return loadDonationIdsLength()
      .then(loadDonationIds)
      .then(loadDonations)
  }

  var loadDonationIdsLength = function() {
    return new Promise(function(resolve, reject) {
      redis.llen('knownDonationIds', function(err, length) {
        if (err) {
          reject(err)
        } else if (length === null) {
          resolve(0)
        } else {
          console.log('donation ids', length)
          resolve(length)
        }
      })
    })
  }

  var loadDonationIds = function(length) {
    return new Promise(function(resolve, reject) {
      if (length < 1) return resolve([])

      var ids = []
      var countdown = length

      for (var i = 0;i < length;i++) {
        redis.lindex('knownDonationIds', i, function(err, id) {
          if (id) {
            ids.push(id)
          } else {
            Redis.print(err, id)
          }
          if (--countdown < 1) {
            //console.log('loaded ids', ids)
            resolve(ids)
          }
        })
      }
    })
  }

  var loadDonations = function(idsToLoad) {
    return new Promise(function(resolve, reject) {
      if (idsToLoad.length < 1) return resolve([])

      redis.mget(idsToLoad, function(err, replies) {
        if (replies) {
          history = replies.map(function(d) {
            var dm = Donation(JSON.parse(d))
            return dm
          })
          updateMatchesInDonations(history)
          console.log('loaded history', history.length)
          resolve(history)
        } else {
          Redis.print(err, replies)
          reject(err)
        }
      })
    })
  }

  var persistDonation = function(dm) {
    var persist = {
      amount: dm.amount,
      comment: dm.comment,
      donor_name: dm.donor_name,
      donor_image: dm.donor_image,
      id: dm.id,
      raw: dm.raw,
    }
    var key = 'donation'+persist.id
    redis.rpush('knownDonationIds', key, function(idErr, idOkay) {
      if (idErr) {
        Redis.print(idErr, idOkay)
      } else {
        redis.set(key, JSON.stringify(persist), function(err, ok) {
          if (err) {
            Redis.print(err, ok)
          } else {
            donations.push(dm)
            //notifyClients([dm])
            //console.log(donations.length)
            //console.log(dm.id)
          }
        })
      }
    })
  }

  var insertDonation = function(d) {
    var dm = Donation(d)
    if (feed[feedName].process.providerId) {
      persistDonation(dm)
    } else {
      redis.incr('lastDonationId', function(err, lastDonationId) {
        if (err) {
          Redis.print(err, ok)
        } else {
          dm.id = lastDonationId
          persistDonation(dm)
        }
      })
    }
    return dm
  }

  var integrateDonations = function(incoming) {
    var fresh = newItems(donations, incoming)
    if (fresh.length < 1) return
    console.log('new donations', fresh.length)
    updateMatchesInDonations(fresh.map(insertDonation))
  }

  var update = function() {
    feed[feedName].update().then(integrateDonations)
  }

  var autoUpdate = function() {
    update()
    setTimeout(autoUpdate, 10000)
  }

  // goal: find alignment of sequences
  // previous:        1234567
  // incoming:        56789
  // incomingWithinPre^
  //
  // previous:        1234567
  // incoming:            56789
  // incomingWithinPre----^
  //
  // previous:            567
  // incoming:            56789
  // incomingWithinPre    ^
  //
  // previous:            12
  // incoming:            1
  // incomingWithinPre    ^
  var newItems = function(previous, incoming) {
    if (incoming.length < 1) return []
    if (previous.length < 1) return incoming
    var index = 0
    var incomingWithinPrevious = 0
    while (incomingWithinPrevious < previous.length) {
      if (index + incomingWithinPrevious >= previous.length) {
        return incoming.slice(index, incoming.length)
      }
      if (index >= incoming.length) {
        return []
      }
      if (previous[index + incomingWithinPrevious].raw == incoming[index].raw) {
        index++
      } else {
        index = 0
        incomingWithinPrevious++
      }
    }
    return incoming
  }

  var test = function() {
    var assert = require('assert')
    assert.deepEqual(newItems([],
                              []),
                              [])
    assert.deepEqual(newItems([{raw: '1'}],
                              []),
                              [])
    assert.deepEqual(newItems([],
                              [{raw: '2'}]),
                              [{raw: '2'}])
    assert.deepEqual(newItems([{raw: '1'}],
                              [{raw: '2'}]),
                              [{raw: '2'}])
    assert.deepEqual(newItems([{raw: '1'}],
                              [{raw: '1'}, {raw: '2'}]),
                              [{raw: '2'}])
    assert.deepEqual(newItems([{raw: '1'}],
                              [{raw: '1'}, {raw: '2'}, {raw: '3'}]),
                              [{raw: '2'}, {raw: '3'}])
    assert.deepEqual(newItems([{raw: '1'}, {raw: '2'}],
                              [{raw: '2'}, {raw: '3'}]),
                              [{raw: '3'}])
    assert.deepEqual(newItems([{raw: '1'}, {raw: '2'}],
                              [{raw: '1'}]),
                              [])
    require('process').exit()
  }

  loadDonationHistory().then(function(history) {
    donations = history
    autoUpdate()
    //test()
  }, function(err) {
    //console.log(err)
  })
});
