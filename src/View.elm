module View exposing (view)

import Msg exposing (..)
import Menu exposing (MenuItem, OrderItem, BuildItem)
import GameInfo exposing (GameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onFocus, onBlur, onCheck, onClick, onSubmit)
import String

-- VIEW

--view : Model -> Html Msg
view model =
  Html.form [ onSubmit Msg.None ]
    [ div [ class "targeting-section col" ] <| targetingSection model
    , div [ class "menu-section col" ] <| menuSection model
    , div [ class "bottom-section col" ] <| bottomSection model
    ]

targetingSection model =
  [ div [ class "row" ]
    [ div [ class "rounds-header col" ]
      [ h2 [] [ text "Games" ]
      , ul [ class "" ] <| List.map (tabHeader model.round) <| (List.sortBy .name) model.rounds
      ]
    , div [ class "rounds-body col" ] <| List.map (displayRound model) model.rounds
    ]
  ]

menuSection model =
  [ h2 [] [ text "Add Items" ]
  , ul [ class "menu" ] <| List.map displayMenuItem model.menu
  ]

bottomSection model =
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
        [ text "Total "
        , text (donationTotal model.selections |> dollars)
        ]
      , div [ class "message-section" ]
        [ textarea
          [ id "output-message", class "text", readonly True, rows 7, cols 40, onFocus (Select "output-message") ]
          [text (donationText model)]
        , br [] []
        ]
      , h2 []
        [ a [ target "_blank", href "https://ablegamers.donordrive.com/index.cfm?fuseaction=donate.team&teamID=5007" ] [ text "Donate" ]
        ]
      ]
    ]
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

radioChoice : (String -> Msg) -> String -> String -> String -> String -> Html Msg
radioChoice msg name current val lab =
  li []
    [ input [type' "radio", Html.Attributes.name name, id name, value val, onCheck (\_ -> msg val), checked (val == current)] []
    , label [ for name ] [text lab]
    ]

tabHeader : String -> GameInfo -> Html Msg
tabHeader current round =
  radioChoice ChooseRound "game" current round.id round.name

displayPlayer : String -> String -> String -> Html Msg
displayPlayer context current name =
  radioChoice SetPlayer (context ++ "-player") current name name

displayPlanet : String -> String -> String -> Html Msg
displayPlanet context current name =
  radioChoice SetPlanet (context ++ "-planet") current name name

displayOrders : List OrderItem -> Html Msg
displayOrders selections =
  let
    visible = nonZero selections
  in 
    if (List.isEmpty visible) then
      p [] [ text "Make selections above" ]
    else
      table []
        [ thead []
          [ th [ class "line-total" ] [ text "$line" ]
          , th [ class "donation" ] [ text "$ea" ]
          , th [ class "quantity" ] [ text "qty" ]
          , th [ class "code" ] [ text "code" ]
          , th [ class "builds" ] [ text "units each" ]
          ]
        , tbody [] <| List.map displayOrderItem visible
        , tfoot []
          [ th [ class "line-total" ]
            [ text <| dollars <| donationTotal visible ]
          ]
        ]

displayOrderItem : OrderItem -> Html Msg
displayOrderItem item =
  tr [ class "order-item" ]
    [ td [ class "line-total" ]
      [ text <| dollars (item.donation * (toFloat item.quantity))
      ]
    , td [ class "donation" ]
      [ text <| dollars item.donation
      ]
    , td [ class "quantity" ] [ input [ size 5, value (item.input), onInput (TypeAmount item.code), onBlur (FinishAmount item.code)  ] [] ]
    , td [ class "code" ] [ text item.code ]
    , td [ class "builds" ] [ ul [] <| List.map displayBuild item.build ]
    ]

displayMenuItem : MenuItem -> Html Msg
displayMenuItem item =
  li [ class "menu-item" ]
    [ button [ onClick (AddOne item.code) ]
      [ div [] <| List.map buildImage item.build
      , span [ class "menu-code" ] [ text item.code ]
      , span [ class "menu-donation" ] [ text <| dollars item.donation ]
      --, ul [] <| List.map displayBuild item.build
      ]
    ]

buildImage : BuildItem -> Html Msg
buildImage build =
  if String.isEmpty build.image then
    text ""
  else
    img [ src build.image, alt build.display_name, title ((toString build.quantity)++" "++build.display_name) ] []

displayBuild : BuildItem -> Html Msg
displayBuild build =
  li [ class "build" ]
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

dollars : Float -> String
dollars n =
  "$"++(toString n)
