var Redis = require('redis')
var redis = Redis.createClient()
redis.on('error', function(err) {
  console.log('Redis error', err)
})

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
  redis.get('game', function(err, reply) {
    if (reply) {
      res.json(JSON.parse(reply))
    } else {
      res.sendStatus(404)
    }
  })
});

app.put('/options.json', jsonParser, function(req, res){
  redis.set('game', JSON.stringify(req.body), function(err, reply) {
    if (reply == 'OK') {
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
