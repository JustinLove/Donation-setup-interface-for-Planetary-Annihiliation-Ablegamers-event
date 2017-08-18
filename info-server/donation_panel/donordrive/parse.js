define([], function() {
  var $ = require('cheerio')

  var process = function(html) {
    // jQuery y u fetch images?
    html = html.replace(/<img/g, '<ximg')
    // trim: leading blank line will throw invalid
    var $donors = $(html.trim()).find('#donors td, #team td')
    //console.log([html, $donors])
    return $donors.map(function(i, donor) {
      var donorAmount = $(donor).find('strong.block').text().split('donated')
      if (donorAmount.length >= 2) {
        var amount = parseInt(donorAmount[1].match(/\d+(\.\d+)?/)[0], 10)
      } else {
        var amount = 0
      } 
      var donor_name = donorAmount[0].trim()
      var donor_image = $(donor).find('ximg.member-avatar').attr('src').replace(/^\/\//, 'http://')
      var comment = $(donor).find('em').html() || ''
      comment = $('<div/>').html(comment.replace(/<br>/g, "\n")).text().trim()

      return {
        amount: amount,
        comment: comment,
        donor_name: donor_name,
        donor_image: donor_image,
        id: donor_name + amount.toString() + comment,
        raw: $(donor).html(),
      }
    }).get().reverse()
  }

  return {
    process: process,
  }
})
