define(['sandbox_unit_menu/discounts'], function(discounts) {
  var atLeastThree = /\b\w{3,}\b/g
  var commonWords = /^(the|with|and|you|that|that's|was|for|his|her|they|have|this|from|had|but|what|there|were|your|when|use|how|she|which|their|then|them|these|him|hers|has|did|than|any|where|one)$/i
  var prototype = {
    matchPlayers: function(players) {
      var words = this.comment.match(atLeastThree)
      if (!words) return

      var uncommonWords = words.filter(function(word) {
        return !word.match(commonWords)
      })

      var re = new RegExp(uncommonWords.join('|'), 'i')
      this.matchingPlayers = players.filter(function(player) {
        return player.match(re)
      })
      if (this.matchingPlayers.length == 1) {
        this.matchingPlayerIndex = players.indexOf(this.matchingPlayers[0])
      }
    },
    matchPlanets: function(planets) {
      var words = this.comment.match(atLeastThree)
      if (!words) return

      var uncommonWords = words.filter(function(word) {
        //console.log(word, word.match(commonWords))
        return !word.match(commonWords)
      })

      var re = new RegExp(uncommonWords.join('|'), 'i')
      this.matchingPlanets = planets.filter(function(planet) {
        return planet && planet.match(re)
      })
      if (this.matchingPlanets.length == 1) {
        this.matchingPlanetIndex = planets.indexOf(this.matchingPlanets[0])
      }
    },
    matchMatches: function(matchTags) {
      var words = this.comment.match(atLeastThree)
      if (!words) return

      var re = new RegExp(words.join('|'), 'i')
      this.matchingMatches = matchTags.filter(function(match) {
        return match && match.match(re)
      })
    },
    matchMenu: function(menu) {
      this.codes = menu.match(this.comment)
      this.orders = discounts.discounts(menu.orders(this.codes), this.discount_level)

      compressBulkMultiples(this)

      this.minimum = this.orders
        .map(function(o) {return o.donation})
        .reduce(function(a, b) {return a + b}, 0)
      this.insufficient = this.minimum > this.amount

      expandSimpleMultiples(this)

      this.unaccounted = this.minimum < this.amount
    },
  }

  var expandSimpleMultiples = function(model) {
    if (model.orders.length == 1) {
      var credit = model.amount
      var item = model.orders[0]
      credit -= item.donation
      if (item.build.length == 1 && item.build[0][0] > 1) {
        var step = item.build[0][0]
        while (credit >= item.donation) {
          credit -= item.donation
          model.minimum += item.donation
          item.build[0][0] += step
        }
      } else {
        while (credit >= item.donation) {
          credit -= item.donation
          model.minimum += item.donation
        }
      }
    }
  }

  var compressBulkMultiples = function(model) {
    var i = 0
    while (i+1 < model.orders.length) {
      var base = model.orders[i]
      var next = model.orders[i+1]
      if (base.code == next.code
       && base.build.length == 1
       && base.build[0][0] > 1) {
        base.donation += next.donation
        base.build[0][0] += next.build[0][0]
        model.orders.splice(i+1, 1)
      } else {
        i++
      }
    }
  }

  var constructor = function(donation) {
    var model = Object.create(prototype)
    Object.assign(model, donation)
    model.amount = model.amount || 0
    model.donor_name = model.donor_name || 'anonymous'
    model.donor_image = model.donor_image || ''
    model.comment = model.comment || ''
    model.comment = (model.comment || '').replace(/^\s+|\s+$/gm, '')
    model.discount_level = model.discount_level || 0

    model.matchingPlayers = []
    model.matchingPlayerIndex = -1
    model.matchingPlanets = []
    model.matchingPlanetIndex = -1
    model.matchingMatches = []

    return model
  }

  return constructor
})
