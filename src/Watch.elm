import Watch.View exposing (view, WVMsg(..))
import GameInfo exposing (GameInfo) 
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
  }

makeModel : Model
makeModel =
  { rounds = []
  , round = ""
  }

init : (Model, Cmd Msg)
init =
  ( makeModel
  , fetchGame
  )

fetchGame : Cmd Msg
fetchGame =
  Http.send GotGameInfo (Http.get (config.server ++ "options.json") GameInfo.rounds)

-- UPDATE

type Msg
  = GotGameInfo (Result Http.Error (List GameInfo))
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
      let _ = Debug.log "error" msg in
      (model, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

