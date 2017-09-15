define([
  'donation_data/tiltify/local',
  'donation_data/tiltify/api_test',
  'donation_data/tiltify/live',
  'donation_data/donordrive/test',
  'donation_data/donordrive/live',
], function(
  tiltify_local,
  tiltify_api_test,
  tiltify_live,
  donordrive_test,
  donordrive_live
) {
  return {
    tiltify_local: tiltify_local,
    tiltify_api_test: tiltify_api_test,
    tiltify_live: tiltify_live,
    donordrive_test: donordrive_test,
    donordrive_live: donordrive_live,
  }
})
