var Redis = require('redis')
var redis = Redis.createClient(process.env.REDIS_URL)
redis.on('error', function(err) {
  console.log('Redis error', err)
})

var nacl
var signpk
require('js-nacl').instantiate(function(n) {
  nacl = n
  if (process.env.SIGNPK) {
    signpk = nacl.from_hex(process.env.SIGNPK)
  }
})

var feedName = process.env.FEED

var fetchOptions = function() {
  return new Promise(function(resolve, reject) {
    redis.smembers('games', function(err, games) {
      if (games) {
        redis.mget(games, function(err2, replies) {
          if (replies) {
            resolve({games: replies.map(JSON.parse)})
          } else {
            reject(err2)
          }
        })
      } else {
        reject(err)
      }
    })
  })
}

var express = require('express');
var app = express();
var bodyParser = require('body-parser')
var jsonParser = bodyParser.json()

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  res.header("Access-Control-Allow-Methods", "GET, PUT, DELETE, POST, OPTIONS");
  next();
});

app.use(express.static('public'));

app.get('/options.json', function(req, res){
  fetchOptions().then(function(data) {
    res.json(data)
  }, function() {
    res.sendStatus(404)
  })
});

app.put('/games/:id', jsonParser, function(req, res){
  if (!signpk) {
    console.log('no public key')
    res.sendStatus(500)
    return
  }
  var signed = nacl.from_hex(req.body.data)
  try {
    var binfo = nacl.crypto_sign_open(signed, signpk)
  } catch (e) {
    console.log('nacl exception', e)
    res.sendStatus(500)
    return
  }
  if (!binfo) {
    console.log('no binfo')
    res.sendStatus(401)
    return
  }
  var sinfo = nacl.decode_utf8(binfo)
  var info = JSON.parse(sinfo)
  console.log('info', info)
  info.id = req.params.id
  redis.set(req.params.id, JSON.stringify(info), function(err, reply) {
    if (reply == 'OK') {
      redis.sadd('games', req.params.id)
      res.sendStatus(200)
    } else {
      res.sendStatus(507)
    }
  })
});

app.delete('/games/:id', jsonParser, function(req, res){
  if (!signpk) {
    console.log('no public key')
    res.sendStatus(500)
    return
  }
  var signed = nacl.from_hex(req.body.data)
  try {
    var bid = nacl.crypto_sign_open(signed, signpk)
  } catch (e) {
    console.log('nacl exception', e)
    res.sendStatus(500)
    return
  }
  if (!bid) {
    console.log('no bid')
    res.sendStatus(401)
    return
  }
  var sid = nacl.decode_utf8(bid)
  if (sid != req.params.id) {
    console.log('target id mismatch')
    res.sendStatus(401)
    return
  }
  redis.del(req.params.id, function(err, reply) {
    if (reply == 1) {
      redis.srem('games', req.params.id)
      res.sendStatus(204)
    } else {
      res.sendStatus(507)
    }
  })
});

app.get('/donations', function(req, res){
  res.json({donations: donations.map(function(dm) {
    return {
      amount: dm.amount,
      comment: dm.comment,
      donor_name: dm.donor_name,
      donor_image: dm.donor_image,
      id: dm.id,
      matchingMatches: dm.matchingMatches,
    }
  })})
});

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require
});

var donations = []

requirejs(['donation_panel/feed', 'donation_panel/donation'], function (feed, Donation) {
  var loadDonationHistory = function() {
    return loadLastDonationid().then(loadDonationsUpTo)
  }

  var loadLastDonationid = function() {
    return new Promise(function(resolve, reject) {
      redis.get('lastDonationId', function(err, id) {
        if (err) {
          reject(err)
        } else if (id === null) {
          redis.set('lastDonationId', 0)
          resolve(0)
        } else {
          console.log('last donation id', id)
          resolve(parseInt(id, 10))
        }
      })
    })
  }

  var loadDonationsUpTo = function(lastDonationId) {
    return new Promise(function(resolve, reject) {
      if (lastDonationId < 1) return resolve([])

      var idsToLoad = new Array(lastDonationId)
      for (var id = 1;id <= lastDonationId;id++) {
        idsToLoad[id-1] = 'donation'+id.toString()
      }
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

  var persistDonation = function(dm) {
    var persist = {
      amount: dm.amount,
      comment: dm.comment,
      donor_name: dm.donor_name,
      donor_image: dm.donor_image,
      id: dm.id,
      raw: dm.raw,
    }
    redis.set('donation'+persist.id, JSON.stringify(persist), function(err, ok) {
      if (err) {
        Redis.print(err, ok)
      } else {
        donations.push(dm)
        //console.log(donations.length)
        //console.log(dm.id)
      }
    })
  }

  var insertDonation = function(d) {
    var dm = Donation(d)
    //dm.matchMatches(config.match_tags(), config.current_match())
    redis.incr('lastDonationId', function(err, lastDonationId) {
      if (err) {
        Redis.print(err, ok)
      } else {
        dm.id = lastDonationId
        persistDonation(dm)
      }
    })
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

app.set('port', (process.env.PORT || 5000));


app.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});

