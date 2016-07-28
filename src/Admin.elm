import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Nacl

import String
import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Task
import Json.Encode

main : Program Never
main =
  Html.App.program
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
  Task.perform FetchError GotGameInfo (Http.get GameInfo.rounds (config.server ++ "options.json"))

-- UPDATE

type Msg
  = GotGameInfo (List GameInfo)
  | SetKey String
  | Deleted Http.Response
  | FetchError Http.Error
  | FetchRawError Http.RawError
  | DeleteRound String
  | None

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotGameInfo rounds ->
      ({ model | rounds = rounds}, Cmd.none)
    SetKey signsk ->
      if (String.length signsk) == 128 then
        ({ model | signsk = signsk }, fetchGame)
      else
        (model, Cmd.none)
    Deleted reponse ->
      (model, Cmd.none)
    FetchError msg ->
      let _ = Debug.log "error" msg in
      (model, Cmd.none)
    FetchRawError msg ->
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
  Task.perform FetchRawError Deleted (Http.send Http.defaultSettings
    { verb = "DELETE"
    , headers = [ ("Content-Type", "application/json;charset=utf-8") ]
    , url = config.server ++ "games/" ++ round
    , body = message key round |> Http.string
    })

signedBody : String -> String -> String
signedBody key round =
  let
    msg = Nacl.encode_utf8 round
    signsk = Nacl.from_hex key
    signed = Nacl.crypto_sign msg signsk
  in
    Nacl.to_hex signed

message : String -> String -> String
message key id =
  Json.Encode.object
    [ ("id", Json.Encode.string id)
    , ("data", Json.Encode.string <| signedBody key id)
    ]
  |> Json.Encode.encode 0


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
