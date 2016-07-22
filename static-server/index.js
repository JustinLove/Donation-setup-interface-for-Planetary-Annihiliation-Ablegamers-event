var express = require('express');
var app = express();

app.use(express.static('public'));

app.set('port', (process.env.PORT || 5000));

app.listen(app.get('port'), function(){
  console.log('listening on *:', app.get('port'));
});
