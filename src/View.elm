module View exposing (view)

import Msg exposing (..)
import Menu exposing (MenuItem, OrderItem, BuildItem)
import GameInfo exposing (GameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onBlur, onCheck, onClick, onSubmit)
import String

-- VIEW

--view : Model -> Html Msg
view model =
  Html.form [ onSubmit Msg.None ]
    [ div [ class "targeting-section col" ]
      [ div [ class "row" ]
        [ div [ class "rounds-header col" ]
          [ h2 [] [ text "Games" ]
          , ul [ class "" ] <| List.map (tabHeader model.round) <| (List.sortBy .name) model.rounds
          ]
        , div [ class "rounds-body col" ] <| List.map (displayRound model) model.rounds
        ]
      ]
    , div [ class "menu-section col" ]
      [ h2 [] [ text "Add Items" ]
      , ul [ class "menu" ] <| List.map displayMenuItem model.menu
      ]
    , div [ class "bottom col" ]
      [ div [ class "row" ]
        [ div [ class "orders col" ]
          [ h2 [] [ text "Adjust Quantities" ]
          , displayOrders model.selections
          ]
        , div [ class "results col" ]
          [ h2 [] [ text "Submit This" ]
          , p []
            [ small [] [ text "Copy-paste into donation message. You may make additional notes. Please ensure that message and amount remain set to public." ]
            ]
          , p [ class "total" ]
            [ text "Total $"
            , text (donationTotal model.selections |> toString)
            ]
          , div [ class "message-section" ]
            [ textarea
              [ class "text", readonly True, rows 7, cols 40 ]
              [text (donationText model)]
            , br [] []
            ]
          , h2 []
            [ a [ target "_blank", href "https://ablegamers.donordrive.com/index.cfm?fuseaction=donate.team&teamID=5007" ] [ text "Donate" ]
            ]
          ]
        ]
      ]
    ]

tabHeader : String -> GameInfo -> Html Msg
tabHeader current round =
  li [ onClick (ChooseRound round.id) ]
    [ input [type' "radio", Html.Attributes.name "game", value round.id, onCheck (\_ -> ChooseRound round.id), checked (round.id == current)] []
    , label [] [text round.name]
    ]

displayRound model round =
  if model.round == round.id then
    div [ class "row" ]
      [ div [ class "players col" ]
        [ h3 [] [ text "Players" ]
        , ul [] <| List.map (displayPlayer round.id model.player) round.players
        ]
      , div [ class "planets col" ]
        [ h3 [] [ text "Planets" ]
        , ul [] <| List.map (displayPlanet round.id model.planet) round.planets
        ]
      ]
  else
    text ""

displayPlayer : String -> String -> String -> Html Msg
displayPlayer context current name =
  li [ onClick (SetPlayer name) ]
    [ input [type' "radio", Html.Attributes.name (context ++ "-player"), value name, onCheck (\_ -> SetPlayer name), checked (name == current)] []
    , label [] [text name]
    ]

displayPlanet : String -> String -> String -> Html Msg
displayPlanet context current name =
  li [ onClick (SetPlanet name)]
    [ input [type' "radio", Html.Attributes.name (context ++ "-planet"), value name, onCheck (\_ -> SetPlanet name), checked (name == current)] []
    , label [] [text name]
    ]

displayOrders : List OrderItem -> Html Msg
displayOrders selections =
  let
    visible = nonZero selections
  in 
    if List.isEmpty visible then
      p [] [ text "Make selections above" ]
    else
      ul [] <| List.map displayOrderItem visible

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
  li []
    [ button [ onClick (AddOne item.code) ]
      [ div [] <| List.map buildImage item.build
      , text " $"
      , text <| toString item.donation
      , text " "
      , text <| item.code
      --, ul [] <| List.map displayBuild item.build
      ]
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
    [ String.join ", " <| List.filter (not << String.isEmpty) [ model.player, model.planet, model.round ]
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
