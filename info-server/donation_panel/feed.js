define([
  'donation_panel/tiltify/local',
  'donation_panel/tiltify/api_test',
  'donation_panel/tiltify/live',
  'donation_panel/donordrive/test',
  'donation_panel/donordrive/live',
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
