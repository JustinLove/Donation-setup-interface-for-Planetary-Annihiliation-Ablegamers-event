define(['donation_panel/donordrive/parse'], function(parse) {
  var fs = require('fs')

  var testSequence = [
    //"info-server/donation_panel/donordrive/sample.htm",
    //"info-server/donation_panel/donordrive/sample201609.html",
    "info-server/donation_panel/donordrive/donordrive00.html",
    "info-server/donation_panel/donordrive/donordrive01.html",
    "info-server/donation_panel/donordrive/donordrive02.html",
    //"info_server/donation_panel/donordrive/test.htm",
  ]

  var update = function() {
    if (testSequence.length > 1) {
      url = testSequence.shift()
    } else {
      url = testSequence[0]
    }
    return new Promise(function(resolve, reject) {
      fs.readFile(url, 'utf8', function(err, data) {
        if (err) {
          console.log(err)
          reject(err)
        }
        if (data) {
          resolve(parse.process(data))
        }
      })
    })
  }

  return {
    donations: testSequence[0],
    update: update,
    process: parse.process,
  }
})