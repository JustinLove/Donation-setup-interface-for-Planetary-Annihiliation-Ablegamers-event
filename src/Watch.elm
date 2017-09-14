import Watch.View exposing (view, WVMsg(..))
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation) 
import Config exposing (config) 

import Html
import Http

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = \model -> Html.map WatchViewMsg (view model)
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rounds: List GameInfo
  , round: String
  , donations: List Donation
  }

makeModel : Model
makeModel =
  { rounds = []
  , round = ""
  , donations = []
  }

init : (Model, Cmd Msg)
init =
  ( makeModel
  , Cmd.batch [ fetchGame, fetchDonations ]
  )

fetchGame : Cmd Msg
fetchGame =
  Http.send GotGameInfo (Http.get (config.server ++ "options.json") GameInfo.rounds)

fetchDonations : Cmd Msg
fetchDonations =
  Http.send GotDonations (Http.get (config.server ++ "donations") Donation.donations)

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | WatchViewMsg WVMsg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    WatchViewMsg (ChooseRound id) ->
      ({ model | round = id}, Cmd.none)
    WatchViewMsg None ->
      (model, Cmd.none)
    GotGameInfo (Ok rounds) ->
      ({ model | rounds = rounds}, Cmd.none)
    GotGameInfo (Err msg) ->
      let _ = Debug.log "game info error" msg in
      (model, Cmd.none)
    GotDonations (Ok donations) ->
      ({ model | donations = donations}, Cmd.none)
    GotDonations (Err msg) ->
      let _ = Debug.log "donations error" msg in
      (model, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

