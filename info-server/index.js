var express = require('express');
var app = express();
var http = require('http').Server(app);
var path = require('path')

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

app.get('/options.json', function(req, res){
  res.sendFile(__dirname + '/options.json');
});

http.listen(3000, function(){
  console.log('listening on *:3000');
});
