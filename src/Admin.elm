import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Nacl

import String
import Html
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Task
import Json.Encode

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rounds: List GameInfo
  , signsk: String
  }

makeModel : Model
makeModel =
  { rounds = []
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

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
  | SetKey String
  | Deleted (Result Http.Error ())
  | DeleteRound String
  | None

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotGameInfo (Ok rounds) ->
      ({ model | rounds = rounds}, Cmd.none)
    GotGameInfo (Err msg) ->
      let _ = Debug.log "error" msg in
      (model, Cmd.none)
    SetKey signsk ->
      if (String.length signsk) == 128 then
        ({ model | signsk = signsk }, fetchGame)
      else
        (model, Cmd.none)
    Deleted (Ok response) ->
      (model, Cmd.none)
    Deleted (Err msg) ->
      let _ = Debug.log "raw error" msg in
      (model, Cmd.none)
    DeleteRound round ->
      (removeRound round model, deleteRound model.signsk round)
    None ->
      (model, Cmd.none)

removeRound : String -> Model -> Model
removeRound round model =
  { model | rounds = List.filter (\r -> not (r.id == round)) model.rounds }

deleteRound : String -> String -> Cmd Msg
deleteRound key round =
  Http.send Deleted <| Http.request
    { method = "DELETE"
    , headers = []
    , url = config.server ++ "games/" ++ round
    , body = message key round |> Http.jsonBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }

signedBody : String -> String -> String
signedBody key round =
  let
    msg = Nacl.encode_utf8 round
    signsk = Nacl.from_hex key
    signed = Nacl.crypto_sign msg signsk
  in
    Nacl.to_hex signed

message : String -> String -> Json.Encode.Value
message key id =
  Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("data", Json.Encode.string <| signedBody key id)
    ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ p [] [ text config.server ]
    , textarea [ onInput SetKey, rows 3, cols 66 ] [ text model.signsk ]
    , ul [] <| List.map displayRound <| (List.sortBy .name) model.rounds
    ]

displayRound : GameInfo -> Html Msg
displayRound round =
  li [ onClick (DeleteRound round.id) ]
    [ Html.button []
      [ text "X "
      , text round.name
      ]
    ]
