module GameInfo.Encode exposing (game)

import GameInfo exposing (GameInfo)

import Json.Encode exposing (..)

game : GameInfo -> Value
game round =
  object
    [ ("name", string round.name)
    , ("id", string round.id)
    , ("players", list string round.players)
    , ("planets", list string round.planets)
    , ("discount_level", int round.discountLevel)
    , ("game_time", int round.gameTime)
    ]
