module View exposing (view)

import Msg exposing (..)
import Menu exposing (OrderItem, BuildItem)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ div []
      [ text "$"
      , text (List.map (\i -> (toFloat i.quantity) * i.donation) model.selections |> List.sum |> toString)
      ]
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
