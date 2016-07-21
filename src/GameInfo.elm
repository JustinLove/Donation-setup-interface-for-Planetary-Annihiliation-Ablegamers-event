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
  ("games" := list games)

games : Decoder GameInfo
games =
  object4 GameInfo
    ("name" := string)
    ("id" := string)
    ("players" := list string)
    ("planets" := list string)
