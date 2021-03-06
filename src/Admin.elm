module Admin exposing (..)

import Admin.View exposing (Editing(..), AVMsg(..))
import Config exposing (config) 
import Connection exposing (Status(..))
import GameInfo exposing (Options, GameInfo)
import GameInfo.Decode
import GameInfo.Encode
import Donation exposing (Donation)
import Donation.Decode
import Donation.Encode
import Admin.Harbor exposing (..)
import PortSocket
import Nacl

import Browser
import Http
import Json.Encode
import Json.Decode
import Parser
import String
import Task
import Time exposing (Posix)

main : Program () Model Msg
main =
  Browser.document
    { init = init
    , view = Admin.View.document AdminViewMsg
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rounds: List GameInfo
  , donations: List Donation
  , editing: Editing
  , danger: Bool
  , signsk: String
  , optionsConnection : Connection.Status
  , donationsConnection : Connection.Status
  }

makeModel : Model
makeModel =
  { rounds = []
  , donations = []
  , editing = NotEditing
  , danger = False
  , signsk = ""
  , optionsConnection = Disconnected
  , donationsConnection = Disconnected
  }

init : () -> (Model, Cmd Msg)
init _ =
  ( makeModel
  --, Cmd.batch [ fetchGame, fetchDonations]
  , Cmd.none
  )

optionsUrl = config.server ++ "options.json"
optionsWebsocket = config.wsserver ++ "options.json"
donationsUrl =  config.server ++ "donations"
donationsWebsocket =  config.wsserver ++ "donations"

fetchGame : Cmd Msg
fetchGame =
  Http.get
    { url = optionsUrl
    , expect = Http.expectJson GotGameInfo GameInfo.Decode.rounds
    }

fetchDonations : Cmd Msg
fetchDonations =
  Http.get
    { url = donationsUrl
    , expect = Http.expectJson GotDonations Donation.Decode.donations
    }

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | EmptyRequestComplete (Result Http.Error ())
  | MatchedModel (Result Json.Decode.Error Donation)
  | SignedMessage Nacl.SignArguments
  | SocketEvent PortSocket.Id PortSocket.Event
  | Reconnect String Posix
  | KeepAlive PortSocket.Id Posix
  | AdminViewMsg AVMsg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotGameInfo (Ok rounds) ->
      ( { model
        | rounds = rounds
        , optionsConnection = Connection.connect
        }
      , Cmd.none)
    GotGameInfo (Err err) ->
      let _ = Debug.log "error" err in
      (model, Cmd.none)
    GotDonations (Ok donations) ->
      ( { model
        | donations = upsertDonations donations model.donations
        , donationsConnection = Connection.connect
        }
      , Cmd.none)
    GotDonations (Err err) ->
      let _ = Debug.log "donations fetch error" err in
      (model, Cmd.none)
    SocketEvent id (PortSocket.Message message) ->
      --let _ = Debug.log "websocket id" id in
      --let _ = Debug.log "websocket message" message in
      if Just id == (Connection.currentId model.optionsConnection) then
        (updateRounds message model, Cmd.none)
      else if Just id == (Connection.currentId model.donationsConnection) then
        (updateDonations message model, Cmd.none)
      else
        (model, Cmd.none)
    SocketEvent id event ->
      Connection.update id event updateConnection model
    Reconnect url _ ->
      updateConnection url (Connection.socketReconnect url) model
    KeepAlive id _ ->
      (model, PortSocket.send id "")
    EmptyRequestComplete (Ok response) ->
      (model, Cmd.none)
    EmptyRequestComplete (Err err) ->
      let _ = Debug.log "raw error" err in
      (model, Cmd.none)
    MatchedModel (Ok matched) ->
      --let _ = Debug.log "donation" matched in
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingRound _ _ -> (model, Cmd.none)
        EditingDonation edited ->
          let merge = setDonationComment edited.comment matched in
          ( { model | editing = EditingDonation merge }
          , Cmd.none
          )
    MatchedModel (Err err) ->
      let _ = Debug.log "match error" err in
      (model, Cmd.none)
    SignedMessage response ->
      let _ = Debug.log "signed message" response in
      (model, sendSignedRequest response)
    AdminViewMsg (SetKey signsk) ->
      if (String.length signsk) == 128 then
        ( { model | signsk = signsk }
        , Cmd.batch [ fetchGame, fetchDonations]
        )
      else
        (model, Cmd.none)
    AdminViewMsg (DeleteRound round) ->
      ( removeRound round model
      , sendDeleteRound model.signsk round
      )
    AdminViewMsg (EditRound round) ->
      ( { model | editing = case model.editing of
        NotEditing -> EditingRound round.id round
        EditingDonation _ -> EditingRound round.id round
        EditingRound copyId edited ->
          if edited.id == round.id then
            NotEditing
          else
            EditingRound round.id round
      }
      , Cmd.none
      )
    AdminViewMsg (ToggleDanger) ->
      ( { model | danger = not model.danger }
      , Cmd.none
      )
    AdminViewMsg (ClearDonations) ->
      ( { model | donations = [] }
      , sendClearDonations model.signsk
      )
    AdminViewMsg (SetGameTime id input) ->
      let time = parseNumber input in
      ( updateRound (setRoundGameTime time) id model
      , sendGameTime model.signsk id time
      )
    AdminViewMsg (SetDiscountLevel id input) ->
      let level = parseNumber input in
      ( updateRound (setRoundDiscountLevel level) id model
      , sendDiscountLevel model.signsk id level
      )
    AdminViewMsg (SetRoundName name) ->
      updateEditingRound (setRoundName name) model
    AdminViewMsg (SetPlayerName index name) ->
      updateEditingRound (mapPlayers (setName index name)) model
    AdminViewMsg (SetPlanetName index name) ->
      updateEditingRound (mapPlanets (setName index name)) model
    AdminViewMsg (DeletePlayer index) ->
      updateEditingRound (mapPlayers (deleteName index)) model
    AdminViewMsg (DeletePlanet index) ->
      updateEditingRound (mapPlanets (deleteName index)) model
    AdminViewMsg (AddPlayer name) ->
      updateEditingRound (mapPlayers (addName name)) model
    AdminViewMsg (AddPlanet) ->
      updateEditingRound (mapPlanets (addName "")) model
    AdminViewMsg (EditDonation donation) ->
      ( { model | editing = EditingDonation donation }
      , matchInDonation
        { rounds = model.rounds
        , donation = donation
        }
      )
    AdminViewMsg (CommentChange text) ->
      --let _ = Debug.log "change" text in
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingRound _ _ -> (model, Cmd.none)
        EditingDonation edited ->
          let edit = setDonationComment text edited in
          ( { model | editing = EditingDonation edit }
          , matchInDonation
            { rounds = model.rounds
            , donation = edit
            }
          )
    AdminViewMsg (DiscountLevelChange input) ->
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingRound _ _ -> (model, Cmd.none)
        EditingDonation edited ->
          let
            level = parseNumber input
            edit = setDonationDiscountLevel level edited
          in
          ( { model | editing = EditingDonation edit }
          , matchInDonation
            { rounds = model.rounds
            , donation = edit
            }
          )
    AdminViewMsg (DoneEditing) ->
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingRound _ edited ->
          ( updateRound
            (always edited)
            edited.id
            { model | editing = NotEditing }
          , sendRoundEdit model.signsk edited
          )
        EditingDonation edited ->
          ( updateDonation
            (always edited)
            edited.id
            { model | editing = NotEditing }
          , sendDonationEdit model.signsk edited
          )
    AdminViewMsg (CancelEditing) ->
      ( { model | editing = NotEditing }
      , Cmd.none
      )
    AdminViewMsg (SetRoundId id) ->
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingDonation _ -> (model, Cmd.none)
        EditingRound _ edited ->
          ({ model | editing = EditingRound id edited }, Cmd.none)
    AdminViewMsg (CopyRound) ->
      case model.editing of
        NotEditing -> (model, Cmd.none)
        EditingDonation _ -> (model, Cmd.none)
        EditingRound copyId copyFrom ->
          let edited = { copyFrom | id = copyId } in
          ( { model
            | rounds = edited :: model.rounds
            , editing = NotEditing
            }
          , sendRoundEdit model.signsk edited
          )

removeRound : String -> Model -> Model
removeRound round model =
  { model
  | rounds = List.filter (\r -> not (r.id == round)) model.rounds
  , editing = NotEditing
  }

sendSignedRequest : Nacl.SignArguments -> Cmd Msg
sendSignedRequest {method, url, id, body} =
  Http.request
    { method = method
    , headers = []
    , url = url
    , body = signedRequest id body |> Http.jsonBody
    , expect = Http.expectWhatever EmptyRequestComplete
    , timeout = Nothing
    , tracker = Nothing
    }

sendDeleteRound : String -> String -> Cmd Msg
sendDeleteRound key round =
  Nacl.signMessage
    { key = key
    , method = "DELETE"
    , url = config.server ++ "games/" ++ round
    , id = round
    , body = round
    }

sendDiscountLevel : String -> String -> Int -> Cmd Msg
sendDiscountLevel key round level =
  Nacl.signMessage
    { key = key
    , method = "PUT"
    , url = config.server ++ "games/" ++ round ++ "/discount_level"
    , id = round
    , body = discountLevelBody round level
    }

sendRoundEdit : String -> GameInfo -> Cmd Msg
sendRoundEdit key round =
  Nacl.signMessage
    { key = key
    , method = "PUT"
    , url = config.server ++ "games/" ++ round.id
    , id = round.id
    , body = roundEditBody round
    }

sendGameTime : String -> String -> Int -> Cmd Msg
sendGameTime key round time =
  Nacl.signMessage
    { key = key
    , method = "PUT"
    , url = config.server ++ "games/" ++ round ++ "/game_time"
    , id = round
    , body = gameTimeBody round time
    }

sendClearDonations : String -> Cmd Msg
sendClearDonations key =
  Nacl.signMessage
    { key = key
    , method = "DELETE"
    , url = config.server ++ "donations"
    , id = "donations"
    , body = "clear"
    }

sendDonationEdit : String -> Donation -> Cmd Msg
sendDonationEdit key donation =
  Nacl.signMessage
    { key = key
    , method = "PUT"
    , url = config.server ++ "donations/" ++ (String.fromInt donation.id)
    , id = String.fromInt donation.id
    , body = donationEditBody donation
    }

updateDonation : (Donation -> Donation) -> Int -> Model -> Model
updateDonation f id model =
  { model | donations = List.map
            (\d -> if d.id == id then f d else d)
            model.donations
  }

setDonationComment : String -> Donation -> Donation
setDonationComment comment donation =
  { donation | comment = comment}

setDonationDiscountLevel : Int -> Donation -> Donation
setDonationDiscountLevel level donation =
  { donation | discount_level = level}

updateRound : (GameInfo -> GameInfo) -> String -> Model -> Model
updateRound f id model =
  { model | rounds = List.map
      (\r -> if r.id == id then f r else r)
      model.rounds
  }

updateEditingRound : (GameInfo -> GameInfo) -> Model -> (Model, Cmd Msg)
updateEditingRound f model =
  case model.editing of
    NotEditing -> (model, Cmd.none)
    EditingDonation _ -> (model, Cmd.none)
    EditingRound copyId edited ->
      ( { model | editing = EditingRound copyId (f edited) }
      , Cmd.none
      )

setRoundDiscountLevel : Int -> GameInfo -> GameInfo
setRoundDiscountLevel discountLevel round =
  { round | discountLevel = discountLevel}

setRoundGameTime : Int -> GameInfo -> GameInfo
setRoundGameTime gameTime round =
  { round | gameTime = gameTime}

setRoundName : String -> GameInfo -> GameInfo
setRoundName name round =
  { round | name = name}

setRoundId : String -> GameInfo -> GameInfo
setRoundId id round =
  { round | id = id}

mapPlayers : (List String -> List String) -> GameInfo -> GameInfo
mapPlayers f round =
  { round | players = f round.players }

mapPlanets : (List String -> List String) -> GameInfo -> GameInfo
mapPlanets f round =
  { round | planets = f round.planets }

setName : Int -> String -> List String -> List String
setName index newName =
  List.indexedMap (\i name -> if i == index then newName else name )

deleteName : Int -> List String -> List String
deleteName index list =
  List.append
    (List.take index list)
    (List.drop (index+1) list)

addName : String -> List String -> List String
addName name list =
  List.append list [name]

parseNumber : String -> Int
parseNumber discountLevel =
  if validNumber discountLevel then
    getNumber discountLevel
  else
    0

getNumber : String -> Int
getNumber s =
  String.toInt s |> Maybe.withDefault 0

validNumber : String -> Bool
validNumber value =
  case Parser.run Parser.int value of
    Ok _ -> True
    Err _ -> False

signedRequest : String -> String -> Json.Encode.Value
signedRequest id body =
  Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("data", Json.Encode.string body)
    ]

gameTimeBody : String -> Int -> String
gameTimeBody id game_time =
  Json.Encode.encode 0 <| Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("game_time", Json.Encode.int game_time)
    ]

discountLevelBody : String -> Int -> String
discountLevelBody id discount_level =
  Json.Encode.encode 0 <| Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("discount_level", Json.Encode.int discount_level)
    ]

roundEditBody : GameInfo -> String
roundEditBody round =
  Json.Encode.encode 0 <| GameInfo.Encode.game round

donationEditBody : Donation -> String
donationEditBody donation =
  Json.Encode.encode 0 <| Donation.Encode.donation donation

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

updateConnection : String -> (Connection.Status -> (Connection.Status, Cmd Msg)) -> Model -> (Model, Cmd Msg)
updateConnection url f model =
  if url == optionsWebsocket then
    let
      (optionsConnection, cmd) = f model.optionsConnection
    in
      ( { model | optionsConnection = optionsConnection }
      , cmd
      )
  else if url == donationsWebsocket then
    let
      (donationsConnection, cmd) = f model.donationsConnection
    in
      ( { model | donationsConnection = donationsConnection }
      , cmd
      )
  else
    (model, Cmd.none)

updateRounds : String -> Model -> Model
updateRounds message model =
  case Json.Decode.decodeString GameInfo.Decode.rounds message of
    Ok rounds ->
      --let _ = Debug.log "decode" rounds in
      {model | rounds = rounds}
    Err err ->
      let _ = Debug.log "decode error" err in
      model

updateDonations : String -> Model -> Model
updateDonations message model =
  case Json.Decode.decodeString Donation.Decode.donations message of
    Ok donations ->
      --let _ = Debug.log "decode" donations in
      { model | donations = upsertDonations donations model.donations}
    Err err ->
      let _ = Debug.log "decode error" err in
      model

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ PortSocket.receive SocketEvent
    , Connection.reconnect (Reconnect optionsWebsocket) model.optionsConnection
    , Connection.keepAlive 50000 KeepAlive model.optionsConnection
    , Connection.reconnect (Reconnect donationsWebsocket) model.donationsConnection
    , Connection.keepAlive 50000 KeepAlive model.donationsConnection
    , matchSubscription model
    , Nacl.signedMessage SignedMessage
    ]

matchSubscription : Model -> Sub Msg
matchSubscription model =
  case model.editing of
    NotEditing -> Sub.none
    EditingRound _ _ -> Sub.none
    EditingDonation _ -> matchedModel receiveModel

receiveModel : Json.Decode.Value -> Msg
receiveModel =
  MatchedModel << Json.Decode.decodeValue Donation.Decode.donation
