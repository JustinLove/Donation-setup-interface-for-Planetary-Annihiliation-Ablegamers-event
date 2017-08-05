define(['donation_panel/donordrive/parse'], function(parse) {
  var http = require('http')

  var donations = "http://ablegamers.donordrive.com/index.cfm?fuseaction=donorDrive.teamDonations&teamID=5007"
  //var donations = "http://ablegamers.donordrive.com/index.cfm?fuseaction=donorDrive.participantDonations&participantID=1002"
  //var donations = "coui://ui/mods/donation_panel/donordrive/sample.htm"

  var update = function(url) {
    return $.get(url || donations).then(parse.process, function() {
      console.log('fetch failed', arguments)
    })
    return http.get(url, function(res) {
      var error;
      if (res.statusCode !== 200) {
        error = new Error('Request Failed.\n' +
                          `Status Code: ${res.statusCode}`);
      } else if (!/^application\/json/.test(res.headers['content-type'])) {
        error = new Error('Invalid content-type.\n' +
                          `Expected application/json but received ${res.header['content-type']}`);
      }
      if (error) {
        console.error(error.message);
        // consume response data to free up memory
        res.resume();
        return;
      }

      res.setEncoding('utf8');
      var rawData = '';
      res.on('data', (chunk) => { rawData += chunk; });
      res.on('end', () => {
        try {
          parse.process(rawData)
          console.log(rawData);
        } catch (e) {
          console.error(e.message);
        }
      });
    })
  }

  return {
    donations: donations,
    update: update,
    process: parse.process,
  }
})
