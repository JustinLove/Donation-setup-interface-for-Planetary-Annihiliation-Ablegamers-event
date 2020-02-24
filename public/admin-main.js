require(["donation_panel/donation", "donation_panel/menu", "admin"], function(Donation, menu) {
  var app = Elm.Admin.init()

  // ---------------- Harbor -----------------
  app.ports.matchInDonation.subscribe(function(args) {
    var dm = Donation(args.donation)
    dm.matchMenu(menu)
    var matches = args.rounds.map(function(r) {return r.id})
    dm.matchMatches(matches)
    var relevant = args.rounds.filter(function(r) {return dm.matchingMatches.indexOf(r.id) != -1})

    var planets = []
    relevant.forEach(function(r) {planets = planets.concat(r.planets)})
    dm.matchPlanets(planets)

    var players = []
    relevant.forEach(function(r) {players = players.concat(r.players)})
    dm.matchPlayers(players)

    //console.log(dm)
    setTimeout(app.ports.matchedModel.send, 0, dm)
  })

  // ---------------- Nacl -----------------
  nacl_factory.instantiate(function(nacl) {
    app.ports.signMessage.subscribe(function(args) {
      var msg = nacl.encode_utf8(args.body)
      var signsk = nacl.from_hex(args.key)
      var signed = nacl.crypto_sign(msg, signsk)
      var response = Object.create(args)
      response.body = nacl.to_hex(signed)
      app.ports.signedMessage.send(response)
    })
  })

  // ---------------- PortSocket -----------------
  var command = function(message) {
    //console.log(message)
    var ws
    if ('id' in message) {
      connections.forEach(function(socket) {
        if (socket.id == message.id) {
          ws = socket
        }
      })
      if (!ws) {
        app.ports.webSocketReceive.send({kind: "error", id: message.id, error: "socket id not found"})
        return
      }
    }
    switch (message.kind) {
      case 'connect':
        connect(message.address)
        break
      case 'close':
        ws.close()
        break
      case 'send':
        ws.send(message.data)
        break
    }
  }

  var connections = []
  var nextid = 0

  var connect = function(address) {
    //console.log(address)
    var id = nextid++
    var ws
    try {
      ws = new WebSocket(address)
    } catch (e) {
      console.log(e)
      app.ports.webSocketReceive.send({kind: "error", id: id, error: e})
      return
    }

    ws.id = id
    connections.push(ws)

    app.ports.webSocketReceive.send({kind: "connecting", id: ws.id, url: address})

    ws.onerror = function(event) {
      console.log('js websocket error')
      app.ports.webSocketReceive.send({kind: "error", id: ws.id, error: event})
    }

    ws.onopen = function() {
      //console.log('js websocket opened')
      app.ports.webSocketReceive.send({kind: "open", id: ws.id, url: address})
    }

    ws.onclose = function() {
      console.log('js websocket closed', id)
      app.ports.webSocketReceive.send({kind: "close", id: ws.id, url: address})
      var index = connections.indexOf(ws)
      if (index > -1) connections.splice(index, 1)
    }

    ws.onmessage = function(message) {
      //console.log('js message', message)
      app.ports.webSocketReceive.send({kind: "message", id: ws.id, message: message.data})
    }
  }

  if (app.ports.webSocketCommand) {
    app.ports.webSocketCommand.subscribe(command)
  }
})
