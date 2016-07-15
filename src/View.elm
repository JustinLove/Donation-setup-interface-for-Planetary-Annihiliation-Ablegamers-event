module View exposing (view)

import Msg exposing (..)
import Menu exposing (OrderItem, BuildItem)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onBlur, onCheck)
import String

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ div []
      [ text "$"
      , text (donationTotal model.selections |> toString)
      ]
    , pre [] [text (donationText model)]
    , ul [] <| List.map (displayPlayer model.player) model.players
    , ul [] <| List.map displayItem model.selections
    ]

displayPlayer : String -> String -> Html Msg
displayPlayer current name =
  li []
    [ input [type' "radio", Html.Attributes.name "player", value name, onCheck (\_ -> SetPlayer name), checked (name == current)] []
    , label [] [text name]
    ]

displayItem : OrderItem -> Html Msg
displayItem item =
  li []
    [ input [ size 5, value (item.input), onInput (TypeAmount item.code), onBlur (FinishAmount item.code)  ] []
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

--donationText : Model -> String
donationText model =
  String.join ""
    [ model.player
    , "\n"
    , orderText <| nonZero model.selections
    ]

orderText : List OrderItem -> String
orderText items =
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
