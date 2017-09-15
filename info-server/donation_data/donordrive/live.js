define(['donation_data/donordrive/parse'], function(parse) {
  var http = require('https')

  var donations = "https://ablegamers.donordrive.com/index.cfm?fuseaction=donorDrive.teamDonations&teamID=5007"
  //var donations = "https://ablegamers.donordrive.com/index.cfm?fuseaction=donorDrive.participantDonations&participantID=1002"
  //var donations = "coui://ui/mods/donation_data/donordrive/sample.htm"

  var update = function(url) {
    return new Promise(function(resolve, reject) {
      http.get(url || donations, function(res) {
        var error;
        if (res.statusCode !== 200) {
          error = new Error('Request Failed.\n' +
                            `Status Code: ${res.statusCode}`);
        } else if (!/^text\/html/.test(res.headers['content-type'])) {
          error = new Error('Invalid content-type.\n' +
                            `Expected text/html but received ${res.headers['content-type']}`);
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
            var data = parse.process(rawData)
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
