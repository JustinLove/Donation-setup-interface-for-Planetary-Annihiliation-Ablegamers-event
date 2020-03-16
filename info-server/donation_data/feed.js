define([
  'donation_data/noop/noop',
  'donation_data/tiltifyv2/local',
  'donation_data/tiltifyv3/local',
  'donation_data/tiltifyv3/live',
  'donation_data/donordrive/test',
  'donation_data/donordrive/live',
  'donation_data/donation_config/local',
], function(
  noop,
  tiltify_v2_local,
  tiltify_v3_local,
  tiltify_v3_live,
  donordrive_test,
  donordrive_live,
  donation_config_local
) {
  return {
    noop: noop,
    tiltify_v2_local: tiltify_v2_local,
    tiltify_v3_local: tiltify_v3_local,
    tiltify_v3_live: tiltify_v3_live,
    donordrive_test: donordrive_test,
    donordrive_live: donordrive_live,
    donation_config_local: donation_config_local,
  }
})
