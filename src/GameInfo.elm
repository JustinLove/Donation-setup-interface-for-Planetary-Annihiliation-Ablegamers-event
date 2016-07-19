module GameInfo exposing (GameInfo, info)

import Json.Decode exposing (..)

type alias GameInfo =
  { players: List String
  , planets: List String
  }

info : Decoder GameInfo
info =
  object2 GameInfo
    ("players" := list string)
    ("planets" := list string)
