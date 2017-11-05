require(["donation_panel/donation", "donation_panel/menu", "admin"], function(Donation, menu, Elm) {
  var app = Elm.Admin.fullscreen()

  app.ports.matchInDonation.subscribe(function(args) {
    var dm = Donation(args.donation)
    dm.matchMenu(menu)
    var matches = args.rounds.map(function(r) {return r.id})
    dm.matchMatches(matches)
    console.log(dm)
    app.ports.matchedModel.send(dm)
  })
})
