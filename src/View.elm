module View exposing (view)

import Msg exposing (..)
import Menu exposing (MenuItem, OrderItem, BuildItem)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onBlur, onCheck, onClick)
import String

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ ul [ class "players" ] <| List.map (displayPlayer model.player) model.players
    , ul [ class "menu" ] <| List.map displayMenuItem model.menu
    , div [ class "total" ]
      [ text "$"
      , text (donationTotal model.selections |> toString)
      ]
    , textarea
      [ class "text", readonly True, rows 7, cols 40 ]
      [text (donationText model)]
    , ul [ class "order" ] <| List.map displayOrderItem <| nonZero model.selections
    ]

displayPlayer : String -> String -> Html Msg
displayPlayer current name =
  li []
    [ input [type' "radio", Html.Attributes.name "player", value name, onCheck (\_ -> SetPlayer name), checked (name == current)] []
    , label [] [text name]
    ]

displayOrderItem : OrderItem -> Html Msg
displayOrderItem item =
  li []
    [ input [ size 5, value (item.input), onInput (TypeAmount item.code), onBlur (FinishAmount item.code)  ] []
    , text " $"
    , text <| toString item.donation
    , text " "
    , text <| item.code
    , ul [] <| List.map displayBuild item.build
    ]

displayMenuItem : MenuItem -> Html Msg
displayMenuItem item =
  li [ onClick (AddOne item.code) ]
    [ div [] <| List.map buildImage item.build
    , text " $"
    , text <| toString item.donation
    , text " "
    , text <| item.code
    --, ul [] <| List.map displayBuild item.build
    ]

buildImage : BuildItem -> Html Msg
buildImage build =
  if String.isEmpty build.image then
    text ""
  else
    img [ src build.image ] []

displayBuild : BuildItem -> Html Msg

displayBuild build =
  li []
    [ text <| toString build.quantity
    , text " "
    , text <| build.display_name
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
    , " x"
    , toString item.quantity
    , " ("
    , List.map (buildText item.quantity) item.build |> String.join ", "
    , ")"
    ]

buildText : Int -> BuildItem -> String
buildText quantity build =
  toString (build.quantity * quantity) ++ " " ++ build.display_name

nonZero : List OrderItem -> List OrderItem
nonZero =
  List.filter (\i -> i.quantity > 0)
