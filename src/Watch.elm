import Watch.View exposing (view, RoundSelection(..), HighlightColor(..), WVMsg(..))
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation) 
import Config exposing (config) 

import Dict
import Html
import Http
import Time
import WebSocket
import Json.Decode

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
  , round: RoundSelection
  , roundColors: Dict.Dict String HighlightColor
  , donations: List Donation
  }

makeModel : Model
makeModel =
  { rounds = []
  , round = AllRounds
  , roundColors = Dict.empty
  , donations = []
  }

init : (Model, Cmd Msg)
init =
  ( makeModel
  , Cmd.batch [ fetchGame, fetchDonations AllRounds ]
  )

fetchGame : Cmd Msg
fetchGame =
  Http.send GotGameInfo (Http.get (config.server ++ "options.json") GameInfo.rounds)

fetchDonations : RoundSelection -> Cmd Msg
fetchDonations game =
  Http.send GotDonations (Http.get (config.server ++ (donationsPath game)) Donation.donations)

donationsPath : RoundSelection -> String
donationsPath game =
  case game of
    AllRounds ->
      "donations"
    Round id ->
      "donations?game=" ++ id ++ "&untagged=true"


-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | GotUpdate (Result String (List Donation))
  | WatchViewMsg WVMsg
  | Poll Time.Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    WatchViewMsg (FilterRound id) ->
      ({ model | round = id}, fetchDonations id)
    WatchViewMsg (HighlightRound id color) ->
      ({ model | roundColors = Dict.insert id color model.roundColors}, Cmd.none)
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
      let _ = Debug.log "donations fetch error" msg in
      (model, Cmd.none)
    GotUpdate (Ok donations) ->
      ({ model | donations = List.append model.donations donations}, Cmd.none)
    GotUpdate (Err msg) ->
      let _ = Debug.log "donations update error" msg in
      (model, Cmd.none)
    Poll t ->
      (model, fetchDonations model.round)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  --Time.every (Time.second * 10) Poll
  WebSocket.listen (config.wsserver ++ (donationsPath model.round)) receiveUpdate

receiveUpdate : String -> Msg
receiveUpdate message =
  GotUpdate <| Json.Decode.decodeString Donation.donations message
