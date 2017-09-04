define([], function() {
  var process = function(json) {
    return json.map(function(donation) {
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
      }
    }).reverse()
  }

  return {
    process: process,
  }
})
