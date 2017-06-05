module GameInfo exposing (GameInfo, rounds)

import Json.Decode exposing (..)

type alias GameInfo =
  { name: String
  , id: String
  , players: List String
  , planets: List String
  }

rounds : Decoder (List GameInfo)
rounds =
  (field "games" (list games))

games : Decoder GameInfo
games =
  map4 GameInfo
    (field "name" string)
    (field "id" string)
    (field "players" (list string))
    (field "planets" (list string))
