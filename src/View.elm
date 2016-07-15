module View exposing (view)

import Msg exposing (..)
import Menu exposing (OrderItem, BuildItem)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import String

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ div []
      [ text "$"
      , text (donationTotal model.selections |> toString)
      ]
    , pre [] [text (donationText <| nonZero model.selections)]
    , ul [] <| List.map displayItem model.selections
    ]

displayItem : OrderItem -> Html Msg
displayItem item =
  li []
    [ input [ size 5, value (toString item.quantity), onInput (EnterAmount item.code) ] []
    , text " $"
    , text <| toString item.donation
    , text " "
    , text <| item.code
    , ul [] <| List.map displayBuild item.build
    ]

displayBuild : BuildItem -> Html Msg
displayBuild (n,spec) =
  li []
    [ text <| toString n
    , text " "
    , text <| spec
    ]

donationTotal : List OrderItem -> Float
donationTotal items =
  List.map (\i -> (toFloat i.quantity) * i.donation) items |> List.sum

donationText : List OrderItem -> String
donationText items =
  List.map itemText items |> String.join "\n"

itemText : OrderItem -> String
itemText item =
  String.join ""
    [ item.code
    , "x"
    , toString item.quantity
    , " ("
    , List.map (buildText item.quantity) item.build |> String.join ", "
    , ")"
    ]

buildText : Int -> BuildItem -> String
buildText quantity (n, spec) =
  toString (n * quantity) ++ " " ++ spec

nonZero : List OrderItem -> List OrderItem
nonZero =
  List.filter (\i -> i.quantity > 0)
