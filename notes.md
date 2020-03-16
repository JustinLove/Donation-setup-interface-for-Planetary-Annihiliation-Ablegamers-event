### Central server(s)

- x heroku: websocket timeouts https://devcenter.heroku.com/articles/http-routing#timeouts
  - timeout implemented. not fully tested
- original_comment getting overwritten???
- other auth?
- Multiple puppetmasters - coordination? central feed tracking executions?
  - execution status communication

### Donation Config UI

- (ALL) exclude 'match' from matcha etc
- match updates not propagating
- profile editing
- shutting down websockets when changing tabs?
- shutting down websockets on tab close
- first click noop???
- stats layout cleanup
- admin streamlining and safety
- system upload
- xx oauth?

### Ingame Mod

- filter by player
- update sample data
- x Hermes were not coming in at orbital - hermes specific, requires patch mod
- x "nobody" gave units - timing issue? - could not reproduce
  - saw again intermittently
- include planet in chat message
- Lobby info streamlining
- received discount level? - not currently fetching options
- Legion pushing menu queue off bottom of screen
- x schedule unit paste in sim time
- x Legion blocking chat
- x Donation panel getting confused with planet panel during backlogs
- x Menu design: Menu items with multiples can be auto-combined.
- x Need better integration with bulk paste, current player/unit/quantity summary
  - x colored ghosts?
  - immedite ghosts????

- test data
- queuing things up pre-5-minutes.
  - local data?
  - record to central server? localstorage?
- chat message coordination?

## Testing/Streaming keys

signPk b8deab9af248ad2144c0c5eec322ac5261a8703775b5d99ef44755aa8812fe65
signSk 8d617768768b308f0546309c2088a0a37eee7bf7aa511b7fda083f285bc1711bb8deab9af248ad2144c0c5eec322ac5261a8703775b5d99ef44755aa8812fe65
