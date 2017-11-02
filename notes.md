### Central server(s)

- Central feed of donations
  - x extract page scrapers from game mod into server
    - x load test feed
    - x fetch real data
    - x update data
    - x store data
  - x configuration (ENV?)
    - x feed selection
  - x adding uniques ids
    - x no control of ids - affects loading strategy
    - x tiltify has an id already - should not overwrite it
  - x filter by match
    - x match list
    - x assign match to loaded data
    - x assign match to incoming data
    - x update donation matches if game data changes
    - x endpoint for filtered donations
  - donation feed does not scale
    - x kept in process, possibly not synced: convert to always query
    - x every web server is polling data source: have separate polling process
    - x ids added to redis list mulitple times
    - x match tagging broken
    - x notifications split/removed: redis pubsub?
      - x handle possible duplicates
      - ? forward to websocket clients
    - x do not to do full reload with updates being sent
    - x donation loading duplicated
    - x once version for scheduled task instead of polling?
  - x priority donations
  - x discount level
    - x UI
    - x Admin UI
    - x tag discount level received
    - x return discount level
    - x Watch UI
    - x Donation UI update notification
    - Check for scaling issues
  - x poller error with blank database
  - x reduce log spam
  - x better testing for pubsub/websocket events
  - Uber Auth??
  - add or correct match number
  - Edit the feed: We had a lot of unspecified donations. Some of them of them got clarified out-of-band,  although outright gifts are possible. Have a way for donators to contact someone for retargeting if time allows.

- Multiple puppetmasters - coordination? central feed tracking executions?

### Ingame Mod

- received discount level?
- x websockets?
- queuing things up pre-5-minutes.
  - local data?
  - record to central server? localstorage?
- chat message coordination?
- bringing in edited donations?

### Donation Config UI

- x More explicit instructions. I could try adding some large type to the donation app pointing out that it isn't enough.
- x Unspecified planet. App likely biased to specifying planet. Should add explicit option for unspecified planet (in base) (re: 50 air facs after player left planet)

## Testing/Streaming keys

signPk b8deab9af248ad2144c0c5eec322ac5261a8703775b5d99ef44755aa8812fe65
signSk 8d617768768b308f0546309c2088a0a37eee7bf7aa511b7fda083f285bc1711bb8deab9af248ad2144c0c5eec322ac5261a8703775b5d99ef44755aa8812fe65
