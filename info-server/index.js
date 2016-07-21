var Redis = require('redis')
var redis = Redis.createClient()
redis.on('error', function(err) {
  console.log('Redis error', err)
})

var fetchOptions = function() {
  console.log('fetch')
  return new Promise(function(resolve, reject) {
    console.log('promise')
    redis.smembers('games', function(err, games) {
      console.log(games)
      if (games) {
        redis.mget(games, function(err2, replies) {
          console.log(replies)
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

app.get('/options.json', function(req, res){
  fetchOptions().then(function(data) {
    res.json(data)
  }, function() {
    res.sendStatus(404)
  })
});

app.put('/games/:id', jsonParser, function(req, res){
  req.body.id = req.params.id
  redis.set(req.params.id, JSON.stringify(req.body), function(err, reply) {
    if (reply == 'OK') {
      redis.sadd('games', req.params.id)
      res.sendStatus(200)
    } else {
      res.sendStatus(500)
    }
  })
});

var http = require('http').Server(app);
http.listen(3000, function(){
  console.log('listening on *:3000');
});
