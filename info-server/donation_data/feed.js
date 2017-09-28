define([
  'donation_data/noop/noop',
  'donation_data/tiltify/local',
  'donation_data/tiltify/api_test',
  'donation_data/tiltify/live',
  'donation_data/donordrive/test',
  'donation_data/donordrive/live',
], function(
  noop,
  tiltify_local,
  tiltify_api_test,
  tiltify_live,
  donordrive_test,
  donordrive_live
) {
  return {
    noop: noop,
    tiltify_local: tiltify_local,
    tiltify_api_test: tiltify_api_test,
    tiltify_live: tiltify_live,
    donordrive_test: donordrive_test,
    donordrive_live: donordrive_live,
  }
})
