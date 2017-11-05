define([], function() {
  return {
    discounts: function (menu, discount_level) {
      menu.forEach(function(item) {
        var level = Math.min(discount_level, item.discounts.length-1)
        item.donation = item.discounts[level]
      })
      return menu
    }
  }
})
