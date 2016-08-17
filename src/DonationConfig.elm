import View exposing (view)
import Msg exposing (..)
import Menu exposing (..)
import GameInfo exposing (GameInfo) 
import Config exposing (config) 
import Harbor exposing (..) 

import Html.App
import Http
import Task
import Regex exposing (regex)
import String

type alias Arguments =
  { menu: List RawMenuItem
  , info: List UnitInfo
  }

main : Program Arguments
main =
  Html.App.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { menu : List MenuItem
  , unitInfo: List UnitInfo
  , rounds: List GameInfo
  , round: String
  , player: String
  , planet: String
  , selections : List OrderItem
  , instructionsOpen: Bool
  }

model : List RawMenuItem -> List UnitInfo -> Model
model menu info =
  let
    m2 = cook info menu
  in
    { menu = m2
    , unitInfo = info
    , rounds = []
    , round = ""
    , player = ""
    , planet = ""
    , selections = List.map makeOrder m2
    , instructionsOpen = False
    }

init : Arguments -> (Model, Cmd Msg)
init args =
  ( model args.menu args.info
  , fetchGame
  )

fetchGame : Cmd Msg
fetchGame =
  Task.perform FetchError GotGameInfo (Http.get GameInfo.rounds (config.server ++ "options.json"))

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TypeAmount code number ->
      (updateOrder (updateInput number) code model, Cmd.none)
    FinishAmount code ->
      (updateOrder updateQuantity code model, Cmd.none)
    AddOne code ->
      (updateOrder addOne code model, Cmd.none)
    SetPlayer name ->
      ({ model | player = name}, Cmd.none)
    SetPlanet name ->
      ({ model | planet = name}, Cmd.none)
    ChooseRound id ->
      ({ model | round = id}, Cmd.none)
    GotGameInfo rounds ->
      ({ model | rounds = rounds}, Cmd.none)
    FetchError msg ->
      let _ = Debug.log "error" msg in
      (model, Cmd.none)
    Select id ->
      (model, select id)
    Instructions open ->
      ({model | instructionsOpen = open}, focus <| instructionFocus open)
    None ->
      (model, Cmd.none)

updateOrder : (OrderItem -> OrderItem) -> String -> Model -> Model
updateOrder f code model =
  { model | selections = List.map
      (\i -> if i.code == code then f i else i)
      model.selections
  }

updateInput : String -> OrderItem -> OrderItem
updateInput number item =
  { item | input = number }

updateQuantity : OrderItem -> OrderItem
updateQuantity item =
  if validNumber item.input then
    { item | quantity = getNumber item.input }
  else
    { item | quantity = 0, input = "" }

addOne : OrderItem -> OrderItem
addOne item =
  { item | quantity = item.quantity + 1, input = toString (item.quantity + 1) }

getNumber : String -> Int
getNumber s =
  String.toInt s |> Result.withDefault 0

validNumber : String -> Bool
validNumber value =
  Regex.contains (regex "^\\d+$") value

instructionFocus : Bool -> String
instructionFocus open =
  if open then
    "#navigate-donation"
  else
    "#open-instructions"

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

