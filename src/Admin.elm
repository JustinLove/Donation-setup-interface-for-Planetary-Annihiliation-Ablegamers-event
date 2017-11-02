import Admin.View exposing (view, AVMsg(..))
import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation)
import Nacl

import String
import Html
import Http
import Task
import Json.Encode
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
  , signsk: String
  }

makeModel : Model
makeModel =
  { rounds = []
  , donations = []
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
  Http.send GotDonations (Http.get (config.server ++ "donations") Donation.donations)

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | GotDonations (Result Http.Error (List Donation))
  | EmptyRequestComplete (Result Http.Error ())
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

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
