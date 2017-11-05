module Admin exposing (..)

import Admin.View exposing (view, DonationEdit(..), AVMsg(..))
import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation)
import Donation.Decode
import Donation.Encode
import Admin.Harbor exposing (..)
import Nacl

import String
import Html
import Http
import WebSocket
import Task
import Json.Encode
import Json.Decode
import Regex exposing (regex)

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = \model -> Html.map AdminViewMsg (view model)
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rounds: List GameInfo
  , donations: List Donation
  , editing: DonationEdit
  , signsk: String
  }

makeModel : Model
makeModel =
  { rounds = []
  , donations = []
  , editing = NotEditing
  , signsk = ""
  }

init : (Model, Cmd Msg)
init =
  ( makeModel
  , Cmd.none
  )

fetchGame : Cmd Msg
fetchGame =
  Http.send GotGameInfo (Http.get (config.server ++ "options.json") GameInfo.rounds)

fetchDonations : Cmd Msg
fetchDonations =
  Http.send GotDonations (Http.get (config.server ++ "donations") Donation.Decode.donations)

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | GotUpdate (Result String (List Donation))
  | EmptyRequestComplete (Result Http.Error ())
  | MatchedModel (Result String Donation)
  | AdminViewMsg AVMsg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotGameInfo (Ok rounds) ->
      ({ model | rounds = rounds}, Cmd.none)
    GotGameInfo (Err msg) ->
      let _ = Debug.log "error" msg in
      (model, Cmd.none)
    GotDonations (Ok donations) ->
      ({ model | donations = donations}, Cmd.none)
    GotDonations (Err msg) ->
      let _ = Debug.log "donations fetch error" msg in
      (model, Cmd.none)
    GotUpdate (Ok donations) ->
      ({ model | donations = upsertDonations donations model.donations}, Cmd.none)
    GotUpdate (Err msg) ->
      let _ = Debug.log "donations update error" msg in
      (model, Cmd.none)
    AdminViewMsg (SetKey signsk) ->
      if (String.length signsk) == 128 then
        ( { model | signsk = signsk }
        , Cmd.batch [ fetchGame, fetchDonations ]
        )
      else
        (model, Cmd.none)
    EmptyRequestComplete (Ok response) ->
      (model, Cmd.none)
    EmptyRequestComplete (Err msg) ->
      let _ = Debug.log "raw error" msg in
      (model, Cmd.none)
    MatchedModel (Ok donation) ->
      let _ = Debug.log "donation" donation in
      (model, Cmd.none)
    MatchedModel (Err msg) ->
      let _ = Debug.log "match error" msg in
      (model, Cmd.none)
    AdminViewMsg (DeleteRound round) ->
      ( removeRound round model
      , sendDeleteRound model.signsk round
      )
    AdminViewMsg (ClearDonations) ->
      ( { model | donations = [] }
      , sendClearDonations model.signsk
      )
    AdminViewMsg (SetDiscountLevel id input) ->
      let level = parseDiscountLevel input in
      ( updateRound (setRoundDiscountLevel level) id model
      , sendDiscountLevel model.signsk id level
      )
    AdminViewMsg (EditDonation donation) ->
      ( { model | editing = Editing donation donation.comment }
      , Cmd.none
      )
    AdminViewMsg (CommentChange text) ->
      let _ = Debug.log "change" text in
      case model.editing of
        NotEditing -> (model, Cmd.none)
        Editing donation comment ->
          ( { model | editing = Editing donation text }
          , matchInDonation
            <| Donation.Encode.donation
            <| setDonationComment text donation
          )
    AdminViewMsg (DoneEditing) ->
      case model.editing of
        NotEditing -> (model, Cmd.none)
        Editing donation comment ->
          ( updateDonation
            (setDonationComment comment)
            donation.id
            { model | editing = NotEditing }
          , sendDonationEdit model.signsk (setDonationComment comment donation)
          )
    AdminViewMsg (CancelEditing) ->
      ( { model | editing = NotEditing }
      , Cmd.none
      )

removeRound : String -> Model -> Model
removeRound round model =
  { model | rounds = List.filter (\r -> not (r.id == round)) model.rounds }

sendDeleteRound : String -> String -> Cmd Msg
sendDeleteRound key round =
  Http.send EmptyRequestComplete <| Http.request
    { method = "DELETE"
    , headers = []
    , url = config.server ++ "games/" ++ round
    , body = message key round round |> Http.jsonBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }

sendDiscountLevel : String -> String -> Int -> Cmd Msg
sendDiscountLevel key round level =
  Http.send EmptyRequestComplete <| Http.request
    { method = "PUT"
    , headers = []
    , url = config.server ++ "games/" ++ round ++ "/discount_level"
    , body = discountLevelBody round level |> message key round |> Http.jsonBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }

sendClearDonations : String -> Cmd Msg
sendClearDonations key =
  Http.send EmptyRequestComplete <| Http.request
    { method = "DELETE"
    , headers = []
    , url = config.server ++ "donations"
    , body = message key "donations" "clear" |> Http.jsonBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }

sendDonationEdit : String -> Donation -> Cmd Msg
sendDonationEdit key donation =
  Http.send EmptyRequestComplete <| Http.request
    { method = "PUT"
    , headers = []
    , url = config.server ++ "donations/" ++ (toString donation.id)
    , body = donationEditBody donation |> message key (toString donation.id) |> Http.jsonBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
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

updateRound : (GameInfo -> GameInfo) -> String -> Model -> Model
updateRound f id model =
  { model | rounds = List.map
      (\r -> if r.id == id then f r else r)
      model.rounds
  }

setRoundDiscountLevel : Int -> GameInfo -> GameInfo
setRoundDiscountLevel discountLevel round =
  { round | discountLevel = discountLevel}

parseDiscountLevel : String -> Int
parseDiscountLevel discountLevel =
  if validNumber discountLevel then
    getNumber discountLevel
  else
    0

getNumber : String -> Int
getNumber s =
  String.toInt s |> Result.withDefault 0

validNumber : String -> Bool
validNumber value =
  Regex.contains (regex "^\\d+$") value

signedBody : String -> String -> String
signedBody key body =
  let
    msg = Nacl.encode_utf8 body
    signsk = Nacl.from_hex key
    signed = Nacl.crypto_sign msg signsk
  in
    Nacl.to_hex signed

message : String -> String -> String -> Json.Encode.Value
message key id body =
  Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("data", Json.Encode.string <| signedBody key body)
    ]

discountLevelBody : String -> Int -> String
discountLevelBody id discount_level =
  Json.Encode.encode 0 <| Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("discount_level", Json.Encode.int discount_level)
    ]

donationEditBody : Donation -> String
donationEditBody donation =
  Json.Encode.encode 0 <| Donation.Encode.donation donation

upsertDonations : List Donation -> List Donation -> List Donation
upsertDonations updates donations =
  List.foldr upsertDonation donations updates

upsertDonation : Donation -> List Donation -> List Donation
upsertDonation update donations =
  if List.any (\d -> d.id == update.id) donations then
    donations
      |> List.map (\d -> if d.id == update.id then update else d)
  else
    donations ++ [update]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ WebSocket.listen (config.wsserver ++ "donations") receiveUpdate
    , matchSubscription model
    ]

receiveUpdate : String -> Msg
receiveUpdate message =
  GotUpdate <| Json.Decode.decodeString Donation.Decode.donations message

matchSubscription : Model -> Sub Msg
matchSubscription model =
  case model.editing of
    NotEditing -> Sub.none
    Editing _ _ -> matchedModel receiveModel

receiveModel : Json.Decode.Value -> Msg
receiveModel value =
  MatchedModel <| Json.Decode.decodeValue Donation.Decode.donation value
