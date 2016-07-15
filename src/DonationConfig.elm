import View exposing (view)
import Msg exposing (..)
import Menu exposing (..)

import Html.App
import Regex exposing (regex)
import String

main : Program (List MenuItem)
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
  }

model : List MenuItem -> Model
model menu =
  let
    m2 = compress menu
  in
    { menu = m2
    , selections = List.map makeOrder m2
    , player = ""
    , players = ["Larry", "Moe", "Curly"]
    }

init : List MenuItem -> (Model, Cmd Msg)
init menu =
  ( model menu
  , Cmd.none
  )

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TypeAmount code number ->
      (saveInput model number code, Cmd.none)
    FinishAmount code ->
      (addOrder model code, Cmd.none)
    SetPlayer name ->
      ({ model | player = name}, Cmd.none)

saveInput : Model -> String -> String -> Model
saveInput model number code =
  { model | selections = List.map (updateInput number code) model.selections }

updateInput : String -> String -> OrderItem -> OrderItem
updateInput number code item =
  if item.code == code then
    { item | input = number }
  else
    item

addOrder : Model -> String -> Model
addOrder model code =
  { model | selections = List.map (updateQuantity code) model.selections }

updateQuantity : String -> OrderItem -> OrderItem
updateQuantity code item =
  if item.code == code then
    if validNumber item.input then
      { item | quantity = getNumber item.input }
    else
      { item | quantity = 0, input = "" }
  else
    item

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

