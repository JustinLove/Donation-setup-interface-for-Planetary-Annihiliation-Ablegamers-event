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

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require
});

requirejs(['donation_panel/feed', 'donation_panel/donation'], function (feed, Donation) {
  var knownDonations = {}
  var donations = []

  var integrateDonations = function(incoming) {
    incoming.forEach(function(d) {
      if (!knownDonations[d.id]) {
        var dm = Donation(d)
        //dm.matchMatches(config.match_tags(), config.current_match())
        knownDonations[d.id] = dm
        donations.push(dm)
        //console.log(donations.length)
      }
    })
  }

  var update = function() {
    feed['donordrive_test'].update().then(integrateDonations)
  }

  var autoUpdate = function() {
    update()
    setTimeout(autoUpdate, 10000)
  }
  autoUpdate()
});

app.set('port', (process.env.PORT || 5000));

app.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});
