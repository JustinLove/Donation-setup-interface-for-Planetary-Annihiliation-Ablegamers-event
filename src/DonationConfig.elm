import View exposing (view)
import Msg exposing (..)
import Menu exposing (..)

import Html.App
import Regex exposing (regex)
import String
import Dict exposing (Dict)
import Json.Encode

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
  , selections : List OrderItem
  , player: String
  , players: List String
  , unitInfo: List UnitInfo
  }

model : List RawMenuItem -> List UnitInfo -> Model
model menu info =
  let
    m2 = cook info menu
  in
    { menu = m2
    , selections = List.map makeOrder m2
    , player = ""
    , players = ["Larry", "Moe", "Curly"]
    , unitInfo = info
    }

init : Arguments -> (Model, Cmd Msg)
init args =
  ( model args.menu args.info
  , Cmd.none
  )

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

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

