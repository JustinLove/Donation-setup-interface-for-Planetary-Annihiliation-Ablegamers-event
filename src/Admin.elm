import Config exposing (config) 
import GameInfo exposing (GameInfo) 

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Task

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
  }

model : Model
model =
  { rounds = []
  }

init : (Model, Cmd Msg)
init =
  ( model
  , fetchGame
  )

fetchGame : Cmd Msg
fetchGame =
  Task.perform FetchError GotGameInfo (Http.get GameInfo.rounds (config.server ++ "options.json"))

-- UPDATE

type Msg
  = GotGameInfo (List GameInfo)
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
    Deleted reponse ->
      (model, Cmd.none)
    FetchError msg ->
      let _ = Debug.log "error" msg in
      (model, Cmd.none)
    FetchRawError msg ->
      let _ = Debug.log "raw error" msg in
      (model, Cmd.none)
    DeleteRound round ->
      (removeRound round model, deleteRound round)
    None ->
      (model, Cmd.none)

removeRound : String -> Model -> Model
removeRound round model =
  { model | rounds = List.filter (\r -> not (r.id == round)) model.rounds }

deleteRound : String -> Cmd Msg
deleteRound round =
  Task.perform FetchRawError Deleted (Http.send Http.defaultSettings
    { verb = "DELETE"
    , headers = []
    , url = config.server ++ "games/" ++ round
    , body = Http.empty
    })

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
  ul [] <| List.map displayRound <| (List.sortBy .name) model.rounds

displayRound : GameInfo -> Html Msg
displayRound round =
  li [ onClick (DeleteRound round.id) ]
    [ Html.button []
      [ text "X "
      , text round.name
      ]
    ]
