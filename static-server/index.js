var express = require('express');
var app = express();
var http = require('http').Server(app);

app.use(express.static('public'));

http.listen(3001, function(){
  console.log('listening on *:3001');
});
