var fs = require('fs')
var data = fs.readFileSync(__dirname+'/options.json')
var json = JSON.parse(data)

var Redis = require('redis')
var redis = Redis.createClient()
redis.on('error', function(err) {
  console.log('Redis error', err)
})

var count = json.games.length
var loadGames = function() {
  json.games.forEach(function(game) {
    redis.set(game.id, JSON.stringify(game), function(err, ok) {
      Redis.print(err, ok)
      if (--count == 0) {
        loadList()
      }
    })
  })
}

var games = json.games.map(function(game) {
  return game.id
})
var loadList = function() {
  console.log(games)
  redis.sadd('games', games, function(err, ok) {
    Redis.print(err, ok)
    process.exit()
  })
}


loadGames()
