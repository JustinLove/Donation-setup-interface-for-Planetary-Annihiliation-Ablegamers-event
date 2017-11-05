module GameInfo.Decode exposing (options, rounds)

import GameInfo exposing (GameInfo, Options)

import Json.Decode exposing (..)

options : Decoder Options
options =
  map Options
    rounds

rounds : Decoder (List GameInfo)
rounds =
  (field "games" (list game))

game : Decoder GameInfo
game =
  map5 GameInfo
    (field "name" string)
    (field "id" string)
    (field "players" (list string))
    (field "planets" (list string))
    (field "discount_level" int)
