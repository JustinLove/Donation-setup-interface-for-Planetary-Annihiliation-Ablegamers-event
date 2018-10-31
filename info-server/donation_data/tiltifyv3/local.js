define(['donation_data/tiltifyv3/parse'], function(parse) {
  var fs = require('fs')

  var testSequence = [
    "info-server/donation_data/tiltifyv3/sample.json",
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
          resolve(parse.process(JSON.parse(data)))
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
