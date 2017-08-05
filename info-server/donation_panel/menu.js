define(function() {
  var menu = {
    menu: [],
    menuMap: {},
    match: function(comment) {
      var coder = menu.codes.source
      var multicoder = new RegExp("(" + coder + ")[\\sx]+\\d+", "gi")
      var multicodes = comment.match(multicoder)
      if (multicodes) {
        return _.flatten(multicodes.map(function(s) {
          var extractor = new RegExp("(" + coder + ")[\\sx]+(\\d+)", "i")
          var match = s.match(extractor)
          if (match) {
            var c = match[1].toUpperCase()
            var n = parseInt(match[2], 10)
            var a = new Array(n)
            for (var i = 0;i < n;i++) {a[i] = c}
            return a
          } else {
            return []
          }
        }))
      } else {
        var codes = comment.replace(/x/i, ' ').match(menu.codes) || []
        return codes.map(function(s) {return s.toUpperCase()})
      }
    },
    orders: function(codes) {
      return codes.map(function(c) {
        return JSON.parse(JSON.stringify(menu.menuMap[c]))
      }) || []
    },
    codes: /alsfjdlskfjlkdsjflksajf/
  }

  require(['sandbox_unit_menu/menu'], function(loadedMenu) {
    menu.menu = loadedMenu

    loadedMenu.forEach(function(item) {
      menu.menuMap[item.code] = item
    })

    var bits = Object.keys(menu.menuMap).map(function(code) {
      return "\\b"+code+"\\b"
    })
    menu.codes = new RegExp(bits.join('|') , 'gi')
  })

  return menu
})
