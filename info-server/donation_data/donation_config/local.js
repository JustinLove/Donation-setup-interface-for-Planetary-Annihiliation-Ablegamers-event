define(['donation_data/donation_config/parse'], function(parse) {
  var fs = require('fs')

  var testSequence = [
    //"info-server/donation_data/donation_config/donation_config_2017.json",
    //"info-server/donation_data/donation_config/donation_config_2018.json",
    "info-server/donation_data/donation_config/donation_config_2020.json",
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
