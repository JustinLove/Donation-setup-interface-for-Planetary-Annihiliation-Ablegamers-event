require(["menu", "unit_info", "donate"], function(menu, info, Elm) {
  var app = Elm.DonationConfig.fullscreen({
    menu: menu,
    info: info
  })

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
})
