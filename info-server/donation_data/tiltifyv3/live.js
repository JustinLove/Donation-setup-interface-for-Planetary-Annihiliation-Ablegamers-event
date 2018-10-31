define([
  'donation_data/tiltifyv3/parse',
], function(parse) {
  var http = require('https')
  var URL = require('url')

  //var donations = "https://tiltify.com/api/v3/campaigns/9238/donations" // 2017
  var donations = "https://tiltify.com/api/v3/campaigns/19351/donations" // 2018

  // undocumented parameters:
  // count=10
  // before=donatoinid
  // aftert=donationid

  var api_key = process.env.API_KEY

  var update = function(url) {
    return new Promise(function(resolve, reject) {
      var options = URL.parse(url || donations)
      options.headers = {
        'Authorization': 'Bearer ' + api_key,
      }

      http.get(options, function(res) {
        var error;
        if (res.statusCode !== 200) {
          error = new Error('Request Failed.\n' +
                            `Status Code: ${res.statusCode}`);
        } else if (!/^application\/json/.test(res.headers['content-type'])) {
          error = new Error('Invalid content-type.\n' +
                            `Expected application/json but received ${res.headers['content-type']}`);
        }
        if (error) {
          console.error(error.message);
          // consume response data to free up memory
          res.resume();
          reject(error)
          return
        }

        res.setEncoding('utf8');
        var rawData = '';
        res.on('data', (chunk) => { rawData += chunk; });
        res.on('end', () => {
          try {
            var data = parse.process(JSON.parse(rawData))
            resolve(data)
            return
          } catch (e) {
            console.error(e.message);
            reject(e)
            return
          }
        });
      })
    })
  }

  return {
    donations: donations,
    update: update,
    process: parse.process,
  }
})
