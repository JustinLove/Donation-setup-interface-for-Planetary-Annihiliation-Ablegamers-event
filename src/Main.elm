module Main exposing (..)

import DonationConfig
import Watch
import Main.View exposing (view, Msg(..), State(..))

import Html

main : Program DonationConfig.Arguments Model Msg
main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { donate : DonationConfig.Model
  , watch : Watch.Model
  , state : State
  }

init : DonationConfig.Arguments -> (Model, Cmd Msg)
init args =
  case (DonationConfig.init args, Watch.init) of
    ((donateModel, donateCmd), (watchModel, watchCmd)) ->
      ( { donate = donateModel
        , watch = watchModel
        , state = StateDonate
        }
      , Cmd.batch [ Cmd.map DonateMsg donateCmd, Cmd.map WatchMsg watchCmd ]
      )

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    DonateMsg msg ->
      let (dm, dc) = DonationConfig.update msg model.donate in
      ({ model | donate = dm }
      , Cmd.map DonateMsg dc
      )
    WatchMsg msg ->
      let (wm, wc) = Watch.update msg model.watch in
      ({ model | watch = wm }
      , Cmd.map WatchMsg wc
      )
    ChangeState state ->
      ({ model | state = state }, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Sub.map DonateMsg <| DonationConfig.subscriptions model.donate
    , Sub.map WatchMsg <| Watch.subscriptions model.watch
    ]

