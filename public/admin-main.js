require(["donation_panel/donation", "donation_panel/menu", "admin"], function(Donation, menu, Elm) {
  var app = Elm.Admin.fullscreen()

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
})
