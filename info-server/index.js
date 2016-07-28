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
  redis.del(req.params.id, function(err, reply) {
    if (reply == 1) {
      redis.srem('games', req.params.id)
      res.sendStatus(204)
    } else {
      res.sendStatus(507)
    }
  })
});

app.set('port', (process.env.PORT || 5000));

app.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});
