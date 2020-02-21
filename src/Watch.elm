module Watch exposing (..)

import Watch.View exposing (RoundSelection(..), HighlightColor(..), WVMsg(..))
import GameInfo exposing (GameInfo) 
import GameInfo.Decode
import Donation exposing (Donation) 
import Donation.Decode
import Config exposing (config) 

import Browser
import Dict
import Html
import Http
import Time exposing (Posix)
--import WebSocket
import Json.Decode

view = Watch.View.view >> Html.map WatchViewMsg

main : Program () Model Msg
main =
  Browser.document
    { init = init
    , view = Watch.View.document WatchViewMsg
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

init : () -> (Model, Cmd Msg)
init _ =
  ( makeModel
  , Cmd.batch [ fetchGame, fetchDonations AllRounds ]
  )

refresh : Model -> Cmd Msg
refresh model =
  Cmd.batch [ fetchGame, fetchDonations model.round ]

fetchGame : Cmd Msg
fetchGame =
  Http.get
    { url = config.server ++ "options.json"
    , expect = Http.expectJson GotGameInfo GameInfo.Decode.rounds
    }

fetchDonations : RoundSelection -> Cmd Msg
fetchDonations game =
  Http.get
    { url = config.server ++ (donationsPath game)
    , expect = Http.expectJson GotDonations Donation.Decode.donations
    }

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
  | GotUpdate (Result Json.Decode.Error (List Donation))
  | WatchViewMsg WVMsg
  | Poll Posix

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
    GotGameInfo (Err err) ->
      let _ = Debug.log "game info error" err in
      (model, Cmd.none)
    GotDonations (Ok donations) ->
      ({ model | donations = donations}, Cmd.none)
    GotDonations (Err err) ->
      let _ = Debug.log "donations fetch error" err in
      (model, Cmd.none)
    GotUpdate (Ok donations) ->
      ({ model | donations = upsertDonations donations model.donations}, Cmd.none)
    GotUpdate (Err err) ->
      let _ = Debug.log "donations update error" err in
      (model, Cmd.none)
    Poll t ->
      (model, fetchDonations model.round)

upsertDonations : List Donation -> List Donation -> List Donation
upsertDonations entries donations =
  List.foldr upsertDonation donations entries

upsertDonation : Donation -> List Donation -> List Donation
upsertDonation entry donations =
  if List.any (\d -> d.id == entry.id) donations then
    donations
      |> List.map (\d -> if d.id == entry.id then entry else d)
  else
    donations ++ [entry]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every (10 * 1000) Poll
  --WebSocket.listen (config.wsserver ++ (donationsPath model.round)) receiveUpdate

receiveUpdate : String -> Msg
receiveUpdate message =
  GotUpdate <| Json.Decode.decodeString Donation.Decode.donations message
