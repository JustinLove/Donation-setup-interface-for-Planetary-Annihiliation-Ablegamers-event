define([], function() {
  var update = function() {
    return new Promise(function(resolve, reject) {
      resolve([])
    })
  }

  return {
    donations: "",
    update: update,
    process: function() {return []},
  }
})
