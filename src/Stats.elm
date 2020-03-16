module Stats exposing (..)

import Connection exposing (Status(..))
import Config exposing (config)
import Donation exposing (Donation)
import Donation.Decode
import GameInfo exposing (GameInfo)
import GameInfo.Decode
import Menu
import PortSocket
import Stats.View exposing (SVMsg(..))

import Browser
import Dict
import Html
import Http
import Time exposing (Posix)
import Json.Decode

type alias Arguments =
  { menu: List Menu.RawMenuItem
  , info: List Menu.UnitInfo
  }

view = Stats.View.view >> Html.map StatsViewMsg

main : Program Arguments Model Msg
main =
  Browser.document
    { init = init
    , view = Stats.View.document StatsViewMsg
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rawMenu : List Menu.RawMenuItem
  , menu : List Menu.MenuItem
  , unitInfo: List Menu.UnitInfo
  , rounds: List GameInfo
  , donations: List Donation
  , donationsConnection : Connection.Status
  }

makeModel : List Menu.RawMenuItem -> List Menu.UnitInfo -> Model
makeModel menu info =
  let
    m2 = Menu.cook 0 info menu
  in
    { rawMenu = menu
    , menu = m2
    , unitInfo = info
    , rounds = []
    , donations = []
    , donationsConnection = Disconnected
    }

init : Arguments -> (Model, Cmd Msg)
init {menu, info} =
  ( makeModel menu info
  , Cmd.batch [ fetchGame, fetchDonations ]
  )

refresh : Model -> Cmd Msg
refresh model =
  Cmd.batch [ fetchGame, fetchDonations ]

fetchGame : Cmd Msg
fetchGame =
  Http.get
    { url = config.server ++ "options.json"
    , expect = Http.expectJson GotGameInfo GameInfo.Decode.rounds
    }

fetchDonations : Cmd Msg
fetchDonations =
  Http.get
    { url = config.server ++ "donations"
    , expect = Http.expectJson GotDonations Donation.Decode.donations
    }

donationsWebsocket : String
donationsWebsocket =
  config.wsserver ++ "donations"

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | SocketEvent PortSocket.Id PortSocket.Event
  | Reconnect String Posix
  | StatsViewMsg SVMsg
  | Poll Posix

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    StatsViewMsg None ->
      (model, Cmd.none)
    GotGameInfo (Ok rounds) ->
      ({ model | rounds = rounds}, Cmd.none)
    GotGameInfo (Err err) ->
      let _ = Debug.log "game info error" err in
      (model, Cmd.none)
    GotDonations (Ok donations) ->
      ( { model
        | donations = upsertDonations donations model.donations
        , donationsConnection =
          if model.donationsConnection == Disconnected then
            Connection.connect
          else
            model.donationsConnection
        }
      , Cmd.none)
    GotDonations (Err err) ->
      let _ = Debug.log "donations fetch error" err in
      (model, Cmd.none)
    SocketEvent id (PortSocket.Message message) ->
      --let _ = Debug.log "websocket id" id in
      --let _ = Debug.log "websocket message" message in
      if Just id == (Connection.currentId model.donationsConnection) then
        (updateDonations message model, Cmd.none)
      else
        (model, Cmd.none)
    SocketEvent id event ->
      Connection.update id event updateConnection model
    Reconnect url _ ->
      updateConnection url (Connection.socketReconnect url) model
    Poll t ->
      (model, fetchDonations)

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

updateDonations : String -> Model -> Model
updateDonations message model =
  case Json.Decode.decodeString Donation.Decode.donations message of
    Ok donations ->
      --let _ = Debug.log "decode" donations in
      { model | donations = upsertDonations donations model.donations}
    Err err ->
      let _ = Debug.log "decode error" err in
      model

updateConnection : String -> (Connection.Status -> (Connection.Status, Cmd Msg)) -> Model -> (Model, Cmd Msg)
updateConnection url f model =
  if url == donationsWebsocket then
    let
      (donationsConnection, cmd) = f model.donationsConnection
    in
      ( { model | donationsConnection = donationsConnection }
      , cmd
      )
  else
    (model, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  --Time.every (10 * 1000) Poll
  Sub.batch
    [ PortSocket.receive SocketEvent
    , Connection.reconnect (Reconnect (donationsWebsocket)) model.donationsConnection
    ]
