define([], function() {
  var process = function(json) {
    return json.data.map(function(donation) {
      var id = donation.id
      var amount = parseInt(donation.amount, 10)
      var comment = donation.comment || ''
      var donor_name = donation.name
      var donor_image = ''

      return {
        amount: amount,
        comment: comment,
        donor_name: donor_name,
        donor_image: donor_image,
        id: id,
        raw: JSON.stringify(donation),
      }
    }).reverse()
  }

  process.providerId = true

  return {
    process: process,
  }
})
