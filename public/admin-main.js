require(["donation_panel/donation", "donation_panel/menu", "admin"], function(Donation, menu, Elm) {
  var app = Elm.Admin.fullscreen()

  app.ports.matchInDonation.subscribe(function(donation) {
    var dm = Donation(donation)
    dm.matchMenu(menu)
    console.log(dm)
    app.ports.matchedModel.send(dm)
  })
})
