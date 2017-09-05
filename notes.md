### Central server(s)

- Central feed of donations
  - extract page scrapers from game mod into server
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
  - add or correct match number
  - Edit the feed: We had a lot of unspecified donations. Some of them of them got clarified out-of-band,  although outright gifts are possible. Have a way for donators to contact someone for retargeting if time allows.

- Multiple puppetmasters - coordination? central feed tracking executions?

### Ingame Mod

- queuing things up pre-5-minutes.
  - local data?
  - record to central server? localstorage?
- chat message coordination?
- bringing in edited donations?

### Donation Config UI

- x More explicit instructions. I could try adding some large type to the donation app pointing out that it isn't enough.
- x Unspecified planet. App likely biased to specifying planet. Should add explicit option for unspecified planet (in base) (re: 50 air facs after player left planet)
