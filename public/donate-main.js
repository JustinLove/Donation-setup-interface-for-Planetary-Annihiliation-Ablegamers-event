require(["menu", "unit_info", "main"], function(menu, info) {
  var app = Elm.Main.init({
    flags: {
      menu: menu,
      info: info
    }
  })

  // -------------------Harbor ------------------------
  app.ports.select.subscribe(function(id) {
    setTimeout(function() {
      var el = document.getElementById(id)
      el.focus()
      el.select()
    }, 50)
  })

  app.ports.focus.subscribe(function(selector) {
    setTimeout(function() {
      var nodes = document.querySelectorAll(selector);
      if (nodes.length === 1 && document.activeElement !== nodes[0]) {
        nodes[0].focus();
      }
    }, 50);
  });


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
