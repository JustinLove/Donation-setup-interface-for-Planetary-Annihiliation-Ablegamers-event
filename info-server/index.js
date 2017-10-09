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
var http = require('http').Server(app)
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
  var sinfo = checkSignature(req, res)
  if (!sinfo) return
  var info = JSON.parse(sinfo)
  console.log('info', info)
  info.id = req.params.id
  info.discount_level = 0
  redis.set(req.params.id, JSON.stringify(info), function(err, reply) {
    if (reply == 'OK') {
      redis.sadd('games', req.params.id, function() {
        updateMatchesInDonations(donations)
      })
      res.sendStatus(200)
    } else {
      res.sendStatus(507)
    }
  })
});

app.put('/games/:id/discount_level', jsonParser, function(req, res){
  var sinfo = checkSignature(req, res)
  if (!sinfo) return
  var info = JSON.parse(sinfo)
  console.log('info', info)
  if (info.id != req.params.id) {
    console.log('target id mismatch')
    res.sendStatus(401)
    return
  }
  redis.get(info.id, function(err, reply) {
    if (reply) {
      var game = JSON.parse(reply)
      game.discount_level = info.discount_level

      redis.set(req.params.id, JSON.stringify(game), function(err2, reply2) {
        if (reply2 == 'OK') {
          res.sendStatus(200)
        } else {
          res.sendStatus(507)
        }
      })
    } else {
      res.sendStatus(404)
    }
  })
});

app.delete('/games/:id', jsonParser, function(req, res){
  var sid = checkSignature(req, res)
  if (!sid) return
  if (sid != req.params.id) {
    console.log('target id mismatch')
    res.sendStatus(401)
    return
  }
  redis.del(req.params.id, function(err, reply) {
    if (reply == 1) {
      redis.srem('games', req.params.id, function() {
        // Do not want to untag donations because it affects filtering for untagged donations
        //updateMatchesInDonations(donations)
      })
      res.sendStatus(204)
    } else {
      res.sendStatus(507)
    }
  })
});

app.get('/donations', function(req, res){
  loadDonationHistory().then(function(history) {
    donations = history
    res.json(filterDonations(donations, req.query))
  }, function(err) {
    console.log('donation load failed')
    res.sendStatus(500)
  })
});

var checkSignature = function(req, res) {
  if (!signpk) {
    console.log('no public key')
    res.sendStatus(500)
    return null
  }
  var signed = nacl.from_hex(req.body.data)
  try {
    var binfo = nacl.crypto_sign_open(signed, signpk)
  } catch (e) {
    console.log('nacl exception', e)
    res.sendStatus(500)
    return null
  }
  if (!binfo) {
    console.log('no binfo')
    res.sendStatus(401)
    return null
  }
  return nacl.decode_utf8(binfo)
}

var filterDonations = function(dms, query) {
  var list = dms
  var game
  var untagged = false
  if (typeof(query['game']) == 'string') {
    game = query['game']
  }
  if (typeof(query['untagged']) == 'string') {
    untagged = query['untagged'] == 'true'
  }

  if (game || untagged) {
    list = dms.filter(function(dm) {
      if (untagged && dm.matchingMatches.length < 1) {
        return true
      } else if (game && dm.matchingMatches.indexOf(game) != -1) {
        return true
      } else {
        return false
      }
    })
  }
  return {donations: list.map(function(dm) {
    return {
      amount: dm.amount,
      comment: dm.comment,
      donor_name: dm.donor_name,
      donor_image: dm.donor_image,
      id: dm.id,
      matchingMatches: dm.matchingMatches,
      //matchingPlayers: dm.matchingPlayers,
      //matchingPlanets: dm.matchingPlanets,
      codes: dm.codes,
      //orders: dm.orders,
      minimum: dm.minimum,
      insufficient: dm.insufficient,
      unaccounted: dm.unaccounted,
    }
  })}
}

var WebSocketServer = require('ws').Server
var wss = new WebSocketServer({ server: http })
var Url = require('url')

var websocketQuery = function(con) {
  var url = Url.parse(con.upgradeReq.url)
  var params = new Url.URLSearchParams(url.search)
  return {
    game: params.get('game'),
    untagged: params.get('untagged')
  }
}

wss.on('connection', function connection(con) {
  var query = websocketQuery(con)
  console.log('connection', query)
  con.on('message', function incoming(message) {
    console.log('received: %s', wss.clients.length, message);
  });

  con.on('close', function() {
    console.log('close')
  })
});

var simulation = function() {
  var dms = [].concat(donations)
  var simulate = function() {
    var dm = dms.shift()
    if (dm) {
      notifyClients([dm])
      setTimeout(simulate, 1000)
    }
  }
  simulate()
}

var notifyClients = function(dms) {
  wss.clients.forEach(function(con) {
    var query = websocketQuery(con)
    var struct = filterDonations(dms, query)
    if (struct.donations.length > 0) {
      con.send(JSON.stringify(struct))
    }
  })
}

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

var loadDonationHistory = function() {
  return new Promise(function(resolve, reject) {reject("stub function")})
}

requirejs(['donation_data/feed', 'donation_data/donation'], function (feed, Donation) {
  loadDonationHistory = function() {
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
            notifyClients([dm])
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

app.set('port', (process.env.PORT || 5000));


http.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});
