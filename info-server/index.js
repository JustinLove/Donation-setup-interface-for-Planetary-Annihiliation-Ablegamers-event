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

var requirejs = require('requirejs');

requirejs.config({
    nodeRequire: require
});

requirejs(['donation_panel/feed', 'donation_panel/donation'], function (feed, Donation) {
  var donations = []

  var insertDonation = function(d) {
    var dm = Donation(d)
    //dm.matchMatches(config.match_tags(), config.current_match())
    dm.id = 1
    if (donations.length > 0) {
      dm.id = donations[donations.length - 1].id + 1
    }
    donations.push(dm)
    //console.log(donations.length)
    //console.log(dm.id)
  }

  var integrateDonations = function(incoming) {
    var fresh = newItems(donations, incoming)
    fresh.forEach(insertDonation)
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

  autoUpdate()
  //test()
});

app.set('port', (process.env.PORT || 5000));


app.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});

