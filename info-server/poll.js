'use strict';

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
var redisSubscriptions = redis.duplicate()

var feedName = process.env.FEED

var notifySubscribers = function(id) {
  //console.log('notify', id)
  redis.publish("new-donation", id)
}

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require
});

var donations = []

var promiseStub = function() {
  return new Promise(function(resolve, reject) {reject("stub function")})
}

var updateMatchesInDonations = promiseStub

requirejs([
  'donation_data/feed',
  'donation_data/donation',
  'donation_loading'
], function (
  feed,
  Donation,
  donation_loading
) {
  var loading = donation_loading(redis)

  updateMatchesInDonations = loading.updateMatchesInDonations

  var persistDonation = function(dm) {
    var persist = {
      amount: dm.amount,
      comment: dm.comment,
      donor_name: dm.donor_name,
      donor_image: dm.donor_image,
      discount_level: dm.discount_level,
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
            notifySubscribers(key)
            //console.log(donations.length)
            //console.log(dm.id)
          }
        })
      }
    })
  }

  var insertDonation = function(dm) {
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

  var tagRecievedDiscountLevel = function(fresh) {
    return loading.fetchOptions().then(function(options) {
      return fresh.map(function(dm) {
        if (dm.matchingMatches.length == 1) {
          var game = options.games.find(function(g) {
            return g.id == dm.matchingMatches[0]
          })
          if (game) {
            dm.discount_level = game.discount_level
          }
        }
        return dm
      })
    }, function(err) {
      console.log("failure loading options", err)
      return fresh
    })
  }

  var integrateDonations = function(incoming) {
    var fresh = newItems(donations, incoming)
    if (fresh.length < 1) return
    console.log('new donations', fresh.length)
    updateMatchesInDonations(fresh.map(Donation))
      .then(tagRecievedDiscountLevel)
      .then(function(list) {return list.map(insertDonation)})
  }

  var update = function() {
    feed[feedName].update()
      //.then(function(l) {return l.slice(0, 2)})
      .then(integrateDonations)
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

  var simulation = function() {
    var dms = []
    var simulate = function() {
      var dm = dms.shift()
      if (dm) {
        var key = 'donation'+dm.id
        notifySubscribers(key)
      } else {
        redis.publish("clear-donations", "")
        dms = [].concat(donations)
      }
      setTimeout(simulate, 1000)
    }
    simulate()
  }

  loading.loadDonationHistory().then(function(history) {
    donations = history
    if (process.argv[2] == 'simulate') {
      simulation()
    } else {
      autoUpdate()
    }
  }, function(err) {
    //console.log(err)
  })

  redisSubscriptions.on('message', function(channel, message) {
    console.log(arguments)
    if (channel == 'clear-donations') {
      donations = []
    }
  })

  redisSubscriptions.subscribe('clear-donations')
});
