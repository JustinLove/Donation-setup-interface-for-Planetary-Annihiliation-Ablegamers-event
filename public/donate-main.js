require(["menu", "unit_info", "donate"], function(menu, info, Elm) {
  var app = Elm.Main.fullscreen({
    menu: menu,
    info: info
  })

  app.ports.select.subscribe(function(id) {
    setTimeout(function() {
      var el = document.getElementById(id)
      el.focus()
      el.select()
    }, 500)
  })
})
