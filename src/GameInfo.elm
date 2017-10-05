module GameInfo exposing (Options, GameInfo, options, rounds)

import Json.Decode exposing (..)

type alias GameInfo =
  { name: String
  , id: String
  , players: List String
  , planets: List String
  }

type alias Options =
  { discountLevel: Int
  , games: List GameInfo
  }

options : Decoder Options
options =
  map2 Options
    (field "discount_level" int)
    rounds

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
