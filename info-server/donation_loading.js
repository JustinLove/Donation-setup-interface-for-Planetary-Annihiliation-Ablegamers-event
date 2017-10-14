"use strict";
define(['donation_data/donation'], function (Donation) {
  var Redis = require('redis')

  return function(redis) {
    var updateMatchesInDonations = function(list) {
      return loadGameIds().then(function(games) {
        list.forEach(function(dm) {
          dm.matchMatches(games, '')
        })
        return list
      })
    }

    var loadGameIds = function() {
      return new Promise(function(resolve, reject) {
        redis.smembers('games', function(err, games) {
          if (games) {
            console.log('loaded games', games)
            resolve(games)
          } else {
            reject(err)
          }
        })
      })
    }

    var fetchOptions = function() {
      return new Promise(function(resolve, reject) {
        redis.smembers('games', function(err, games) {
          if (games) {
            redis.mget(games, function(err2, replies) {
              if (replies) {
                resolve({games: replies.map(JSON.parse)})
              } else {
                reject(err2)
              }
            })
          } else {
            reject(err)
          }
        })
      })
    }

    var loadDonationHistory = function() {
      return loadDonationIdsLength()
        .then(loadDonationIds)
        .then(loadDonations)
    }

    var clearDonationHistory = function() {
      return loadDonationIdsLength()
        .then(loadDonationIds)
        .then(clearDonations)
        .then(clearDonationIds)
    }

    var loadDonationIdsLength = function() {
      return new Promise(function(resolve, reject) {
        redis.llen('knownDonationIds', function(err, length) {
          if (err) {
            reject(err)
          } else if (length === null) {
            resolve(0)
          } else {
            console.log('donation ids', length)
            resolve(length)
          }
        })
      })
    }

    var loadDonationIds = function(length) {
      return new Promise(function(resolve, reject) {
        if (length < 1) return resolve([])

        var ids = []
        var countdown = length

        for (var i = 0;i < length;i++) {
          redis.lindex('knownDonationIds', i, function(err, id) {
            if (id) {
              ids.push(id)
            } else {
              Redis.print(err, id)
            }
            if (--countdown < 1) {
              //console.log('loaded ids', ids)
              resolve(ids)
            }
          })
        }
      })
    }

    var loadDonations = function(idsToLoad) {
      return new Promise(function(resolve, reject) {
        if (idsToLoad.length < 1) return resolve([])

        redis.mget(idsToLoad, function(err, replies) {
          if (replies) {
            var history = replies.map(function(d) {
              if (d) {
                var dm = Donation(JSON.parse(d))
                return dm
              } else {
                console.log('bogus reply', d)
                return Donation({})
              }
            })
            updateMatchesInDonations(history).then(function() {
              console.log('loaded history', history.length)
              resolve(history)
            })
          } else {
            Redis.print(err, replies)
            reject(err)
          }
        })
      })
    }

    var clearDonations = function(idsToClear) {
      return new Promise(function(resolve, reject) {
        if (idsToClear.length < 1) return resolve([])

        redis.del(idsToClear, function(err, replies) {
          if (replies) {
            Redis.print(err, replies)
            resolve(idsToClear)
          } else {
            Redis.print(err, replies)
            reject(err)
          }
        })
      })
    }

    var clearDonationIds = function(idsToClear) {
      return new Promise(function(resolve, reject) {
        if (idsToClear.length < 1) return resolve([])

        // start > end means delete the whole list
        redis.ltrim('knownDonationIds', 1, 0, function(err, replies) {
          if (replies) {
            Redis.print(err, replies)
            resolve(idsToClear)
          } else {
            Redis.print(err, replies)
            reject(err)
          }
        })
      })
    }

    return {
      fetchOptions: fetchOptions,
      updateMatchesInDonations: updateMatchesInDonations,
      loadDonationHistory: loadDonationHistory,
      clearDonationHistory: clearDonationHistory,
      loadDonations: loadDonations,
    }
  }
});
