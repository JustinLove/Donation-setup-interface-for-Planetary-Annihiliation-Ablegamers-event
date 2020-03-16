module Main exposing (..)

import DonationConfig
import Watch
import Stats
import Main.View exposing (document, Msg(..), State(..))

import Browser

main : Program DonationConfig.Arguments Model Msg
main =
  Browser.document
    { init = init
    , view = document identity
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { donate : DonationConfig.Model
  , watch : Watch.Model
  , stats : Stats.Model
  , state : State
  }

init : DonationConfig.Arguments -> (Model, Cmd Msg)
init args =
  case (DonationConfig.init args, Watch.init (), Stats.init ()) of
    ((donateModel, donateCmd), (watchModel, watchCmd), (statsModel, statsCmd)) ->
      ( { donate = donateModel
        , watch = watchModel
        , stats = statsModel
        , state = StateDonate
        }
      , Cmd.map DonateMsg donateCmd
      )

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    DonateMsg sub ->
      let (dm, dc) = DonationConfig.update sub model.donate in
      ({ model | donate = dm }
      , Cmd.map DonateMsg dc
      )
    WatchMsg sub ->
      let (wm, wc) = Watch.update sub model.watch in
      ({ model | watch = wm }
      , Cmd.map WatchMsg wc
      )
    StatsMsg sub ->
      let (sm, sc) = Stats.update sub model.stats in
      ({ model | stats = sm }
      , Cmd.map StatsMsg sc
      )
    ChangeState state ->
      ({ model | state = state }, initCmd state model)

initCmd : State -> Model -> Cmd Msg
initCmd state model =
  case state of
    StateDonate -> 
      let
        (_, cmd) = DonationConfig.init {menu = [], info = []}
      in Cmd.map DonateMsg cmd
    StateWatch -> 
      Cmd.map WatchMsg (Watch.refresh model.watch)
    StateStats -> 
      Cmd.map StatsMsg (Stats.refresh model.stats)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  case model.state of
    StateDonate -> 
      Sub.map DonateMsg <| DonationConfig.subscriptions model.donate
    StateWatch -> 
      Sub.map WatchMsg <| Watch.subscriptions model.watch
    StateStats -> 
      Sub.map StatsMsg <| Stats.subscriptions model.stats

