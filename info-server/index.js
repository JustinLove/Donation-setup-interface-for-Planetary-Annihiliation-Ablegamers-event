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

var notifySubscribers = function(channel, key) {
  //console.log('notify')
  redis.publish(channel, key || "")
}

var nacl
var signpk
require('js-nacl').instantiate(function(n) {
  nacl = n
  if (process.env.SIGNPK) {
    signpk = nacl.from_hex(process.env.SIGNPK)
  }
})

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

var cookieParser = require('cookie-parser');
app.use(cookieParser())

app.use(function (req, res, next) {
  console.log(req.cookies)
  var cookie = req.cookies['auth']
  if (cookie) {
    redis.get('session-'+cookie, function(err, reply) {
      if (reply) {
        var data = JSON.parse(reply)
        req.session = data
      }
      next()
    })
  } else {
    next()
  }
})

app.post('/admin/session', function(req, res) {
  var id = nacl.to_hex(nacl.crypto_box_random_nonce())
  var data = {}
  redis.setex('session-'+id, 60*60*24, JSON.stringify(data), function(err, reply) {
    if (reply == 'OK') {
      res.header("Set-Cookie", "auth="+id);
      res.sendStatus(201)
    } else {
      res.sendStatus(500)
    }
  })
})

app.delete('/admin/session', function(req, res) {
  var id = req.cookies['auth']
  res.header("Set-Cookie", "auth=; expires=Thu, 01 Jan 1970 00:00:00 GMT");
  redis.del('session-'+id, function(err, reply) {
    if (err) {
      res.sendStatus(507)
    } else {
      res.sendStatus(204)
    }
  })
})

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
  info.game_time = 0
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

var setGameProperty = function(property) {
  return function(req, res){
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
        game[property] = info[property]

        redis.set(req.params.id, JSON.stringify(game), function(err2, reply2) {
          if (reply2 == 'OK') {
            notifySubscribers('options-changed')
            res.sendStatus(200)
          } else {
            res.sendStatus(507)
          }
        })
      } else {
        res.sendStatus(404)
      }
    })
  }
}

app.put('/games/:id/game_time', jsonParser, setGameProperty('game_time'))

app.put('/games/:id/discount_level', jsonParser, setGameProperty('discount_level'))

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
  if (req.query['format'] == 'dump') {
    res.json(dumpDonations(donations))
  } else {
    res.json(filterDonations(donations, req.query))
  }
});

app.put('/donations/:id', jsonParser, function(req, res){
  var sinfo = checkSignature(req, res)
  if (!sinfo) return
  var updates = JSON.parse(sinfo)
  console.log('donation edit', updates)
  if (updates.id != req.params.id) {
    console.log('target id mismatch')
    res.sendStatus(401)
    return
  }
  var key = persistKey(updates)
  redis.get(key, function(gerr, reply) {
    if (reply) {
      var donation = Object.assign(JSON.parse(reply), updates)
      var persist = persistFields(donation)
      redis.set(key, JSON.stringify(persist), function(err, ok) {
        if (err) {
          Redis.print(err, ok)
          res.sendStatus(500)
        } else {
          notifySubscribers('donation-update', key)
          res.sendStatus(204)
        }
      })
    } else {
      res.sendStatus(404)
    }
  })
});

app.delete('/donations', jsonParser, function(req, res){
  var command = checkSignature(req, res)
  if (!command) return
  if (command != 'clear') {
    console.log('not a clear donations command')
    res.sendStatus(401)
    return
  }
  clearDonationHistory().then(function() {
    console.log('donation clear succeeded')
    notifySubscribers('clear-donations') // ends up clearing cache
    res.sendStatus(204)
  }, function(err) {
    console.log('donation clear failed', err)
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
      discount_level: dm.discount_level,
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

var dumpDonations = function(dms) {
  var list = dms
  return {donations: list.map(persistFields)}
}

var WebSocketServer = require('ws').Server
var wss = new WebSocketServer({ server: http })
var Url = require('url')
var QueryString = require('querystring')

var websocketQuery = function(con) {
  var url = Url.parse(con.upgradeReq.url)
  var params = QueryString.parse(url.query)
  params.pathname = url.pathname
  return params
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
      notifyClientsDonations([dm])
      setTimeout(simulate, 1000)
    }
  }
  simulate()
}

var notifyClientsDonations = function(dms) {
  wss.clients.forEach(function(con) {
    var query = websocketQuery(con)
    if (query.pathname == '/donations') {
      var struct = filterDonations(dms, query)
      if (struct.donations.length > 0) {
        con.send(JSON.stringify(struct))
      }
    }
  })
}

var notifyClientsOptionsChanged = function() {
  fetchOptions().then(function(data) {
    var message = JSON.stringify(data)
    wss.clients.forEach(function(con) {
      var query = websocketQuery(con)
      if (query.pathname == '/options.json') {
        con.send(message)
      }
    })
  })
}

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require,
    paths: {
      "donation_panel": "../public/donation_panel",
      "sandbox_unit_menu": "../public/sandbox_unit_menu",
      "menu": "../public/menu",
    }
});

var donations = []

var promiseStub = function() {
  return new Promise(function(resolve, reject) {reject("stub function")})
}

var persistFields = promiseStub
var persistKey = promiseStub
var fetchOptions = promiseStub
var updateMatchesInDonations = promiseStub
var clearDonationHistory = promiseStub

requirejs([
  'donation_loading',
  'donation_panel/menu',
], function (
  donation_loading,
  menu
) {
  var loading = donation_loading(redis)

  persistFields = loading.persistFields
  persistKey = loading.persistKey
  fetchOptions = loading.fetchOptions
  clearDonationHistory = loading.clearDonationHistory
  updateMatchesInDonations = loading.updateMatchesInDonations

  var loadNewDonations = function(idsToLoad) {
    loading.loadDonations(idsToLoad).then(function(dms) {
      updateMenuInDonations(dms)
      dms.forEach(function(dmx) {
        var dm = dmx
        if (donations.every(function(d) {return d.id != dm.id})) {
          notifyClientsDonations([dm])
          donations.push(dm)
        }
      })
    })
  }

  var loadUpdatedDonations = function(idsToLoad) {
    loading.loadDonations(idsToLoad).then(function(dms) {
      updateMenuInDonations(dms)
      dms.forEach(function(dmx) {
        var dm = dmx
        donations = donations.map(function(d) {
          if (d.id == dm.id) {
            notifyClientsDonations([dm])
            return dm
          } else {
            return d
          }
        })
      })
    })
  }

  var updateMenuInDonations = function(dms) {
    dms.forEach(function(dm) {dm.matchMenu(menu)})
  }

  loading.loadDonationHistory().then(function(history) {
    console.log('loaded history', history.length)
    updateMenuInDonations(history)
    donations = history
    //test()
  }, function(err) {
    //console.log(err)
  })

  redisSubscriptions.on('message', function(channel, message) {
    console.log(arguments)
    if (channel == 'donation-create') {
      loadNewDonations([message])
    } else if (channel == 'donation-update') {
      loadUpdatedDonations([message])
    } else if (channel == 'clear-donations') {
      donations = []
    } else if (channel == 'options-changed') {
      notifyClientsOptionsChanged()
    }
  })

  redisSubscriptions.subscribe('donation-create')
  redisSubscriptions.subscribe('donation-update')
  redisSubscriptions.subscribe('clear-donations')
  redisSubscriptions.subscribe('options-changed')
});

app.set('port', (process.env.PORT || 5000));


http.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});
