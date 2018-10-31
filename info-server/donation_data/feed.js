define([
  'donation_data/noop/noop',
  'donation_data/tiltifyv2/local',
  'donation_data/tiltifyv3/local',
  'donation_data/tiltifyv3/live',
  'donation_data/donordrive/test',
  'donation_data/donordrive/live',
], function(
  noop,
  tiltify_v2_local,
  tiltify_v3_local,
  tiltify_v3_live,
  donordrive_test,
  donordrive_live
) {
  return {
    noop: noop,
    tiltify_v2_local: tiltify_v2_local,
    tiltify_v3_local: tiltify_v3_local,
    tiltify_v3_live: tiltify_v3_live,
    donordrive_test: donordrive_test,
    donordrive_live: donordrive_live,
  }
})
