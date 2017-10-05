module GameInfo exposing (Options, GameInfo, options, rounds)

import Json.Decode exposing (..)

type alias GameInfo =
  { name: String
  , id: String
  , players: List String
  , planets: List String
  , discountLevel : Int
  }

type alias Options =
  { games: List GameInfo
  }

options : Decoder Options
options =
  map Options
    rounds

rounds : Decoder (List GameInfo)
rounds =
  (field "games" (list games))

games : Decoder GameInfo
games =
  map5 GameInfo
    (field "name" string)
    (field "id" string)
    (field "players" (list string))
    (field "planets" (list string))
    (succeed 0)
