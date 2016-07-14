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
  }

model : List MenuItem -> Model
model menu =
  let
    m2 = compress menu
  in
    { menu = m2
    , selections = List.map makeOrder m2
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
    EnterAmount code number ->
      if validNumber number then
        ((addOrder model (getNumber number) code), Cmd.none)
      else
        (model, Cmd.none)

addOrder : Model -> Int -> String -> Model
addOrder model number code =
  { model | selections = List.map (updateQuantity number code) model.selections }

updateQuantity : Int -> String -> OrderItem -> OrderItem
updateQuantity number code item =
  if item.code == code then
    { item | quantity = number }
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

