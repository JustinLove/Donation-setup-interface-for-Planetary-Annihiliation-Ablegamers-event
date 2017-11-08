module Main.View exposing (view, Msg(..), State(..))

import DonationConfig
import Watch

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick)

type Msg
  = DonateMsg DonationConfig.DCMsg
  | WatchMsg Watch.Msg

type State
  = StateDonate
  | StateWatch

-- VIEW

--view : Model -> Html.Html Never
view model =
  div []
    [ mainHeader model
    , contents model
    ]

mainHeader model =
  header [ class "row col" ]
    [ a
      [ href "https://tiltify.com/@wondible/planetary-annihilation-ablegamers-tournament-2017"
      , class "logo"
      ]
      [ img
        [ src "logoHeader.png"
        , width 242
        , height 63
        ]
        []
      ]
    ]

contents model =
  case model.state of
    StateDonate ->
      Html.map DonateMsg (DonationConfig.view model.donate)
    StateWatch ->
      Html.map WatchMsg (Watch.view model.watch)

