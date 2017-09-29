module View exposing (view)

import Msg exposing (..)
import Menu exposing (MenuItem, OrderItem, BuildItem)
import GameInfo exposing (GameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onInput, onFocus, onBlur, onCheck, onClick, onSubmit)
import String
import Json.Decode

-- VIEW

characterLimit = 300

--view : Model -> Html Msg
view model =
  div []
    [ div [ ariaHidden model.instructionsOpen ]
      [ header [ class "row col" ]
        [ a
          [ href "http://ablegamers.donordrive.com/"
          , class "logo"
          ]
          [ img
            [ src "logoHeader.png"
            , width 242
            , height 63
            ]
            []
          ]
        ]
      , Html.form [ onSubmit Msg.None, class "row" ]
        [ div [ class "targeting-section col" ] <| targetingSection model
        , div [ class "menu-section col" ] <| menuSection model
        , div [ class "bottom-section col" ] <| bottomSection model
        ]
      ]
    , if model.instructionsOpen then instructions else text ""
    ]

instructions : Html Msg
instructions =
   div [ id "instruction-frame", onKeydown (onKey 27 (Instructions False)) ]
    [ div
      [ id "instruction-dialog"
      , role "dialog"
      , ariaDescribedby "instruction-title"
      ]
      [ h1 [ id "instruction-title" ] [text "Donation Instructions"]
      , img
        [ id "instructions"
        , src "instructions.png"
        , alt "On the upcoming donation page: Choose 'Other' and then enter amount. Paste message into the message box, and add placement suggestions or comments. (Leave message and amount public.)"
        , width 716
        , height 768
        ] []
      , footer []
        [ a
          [ target "_blank"
          , href "https://ablegamers.donordrive.com/index.cfm?fuseaction=donate.team&teamID=5007"
          , class "primary button"
          , id "navigate-donation"
          ] [ text "Take Me There" ]
        , a
          [ onClick (Instructions False)
          , href "#"
          , class "cancel"
          ] [ text "cancel" ]
        ]
      ]
    ]

onKeydown : (Int -> msg) -> Attribute msg
onKeydown tagger =
  Html.Events.on "keydown" (Json.Decode.map tagger Html.Events.keyCode)

onKey : Int -> Msg -> Int -> Msg
onKey trigger msg keycode =
  if keycode == trigger then
    msg
  else
    Msg.None

targetingSection model =
  [ div [ class "row" ]
    [ div [ class "rounds-header col" ]
      [ fieldset []
        [ legend [] [ text "Games" ]
        , ul [] <| List.map (tabHeader model.round) <| (List.sortBy .name) model.rounds
        ]
      ]
    , div [ class "rounds-body col" ] <| List.map (displayRound model) model.rounds
    ]
  ]

menuSection model =
  [ div [ class "row col" ]
    [ fieldset []
      [ legend [] [ text "Add Items" ]
      , ul [ class "menu" ] <| List.map displayMenuItem model.menu
      ]
    ]
  ]

bottomSection model =
  [ div [ class "row" ]
    [ div [ class "orders col" ]
      [ fieldset []
        [ legend [] [ text "Adjust Quantities" ]
        , displayOrders model.selections
        ]
      ]
    , div [ class "results col" ]
      [ fieldset []
        [ legend []
          [ label [ for "output-message" ] [ text "Submit This" ]
          ]
        , p []
          [ span [ id "not-enough" ] [ text "This page is not enough!" ]
          , text " Units are added based on the donation feed at donordrive.com." ]
        , p []
          [ small
            [ id "message-instructions" ]
            [ text "Copy-paste into donation message. You may make additional notes. Please ensure that message and amount remain set to public." ]
          ]
        , p [ class "total" ]
          [ text "Total "
          , text (donationTotal model.selections |> dollars)
          ]
        , div [ class "message-section" ]
          [ textarea
            [ id "output-message"
            , Html.Attributes.name "output-message"
            , ariaDescribedby "message-instructions"
            , class "text"
            , readonly True
            , rows 7
            , cols 40
            , onFocus (Select "output-message")
            ]
            [text (donationText model)]
          , p []
            [ small []
              [ donationText model |> String.length |> toString |> text
              , text (" / " ++ (toString characterLimit) ++ " characters")
              ]
            ]
          , br [] []
          ]
        , h2 []
          [ button
            [ onClick (Instructions True)
            , class "primary button"
            , id "open-instructions"
            ] [ text "Donate" ]
          ]
        ]
      ]
    ]
  ]

displayRound model round =
  if model.round == round.id then
    div [ class "row" ]
      [ div [ class "players col" ]
        [ fieldset []
          [ legend [] [ text "Players" ]
          , ul [] <| List.map (displayPlayer round.id model.player) round.players
          ]
        ]
      , div [ class "planets col" ]
        [ fieldset []
          [ legend [] [ text "Planets" ]
          , ul [] <| List.map (displayPlanet round.id model.planet) ("(main base)" :: round.planets)
          ]
        ]
      ]
  else
    text ""

radioChoice : (String -> Msg) -> String -> String -> String -> String -> Html Msg
radioChoice msg name current val lab =
  li []
    [ input [type_ "radio", Html.Attributes.name name, id val, value val, onCheck (\_ -> msg val), checked (val == current)] []
    , label [ for val ] [text lab]
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
          [ th [ class "line-total", id "order-line-total" ] [ text "$line" ]
          , th [ class "donation", id "order-donation" ] [ text "$ea" ]
          , th [ class "quantity", id "order-quantity" ] [ text "qty" ]
          , th [ class "code", id "order-code" ] [ text "code" ]
          , th [ class "builds", id "order-builds" ] [ text "units each" ]
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
    [ td [ class "line-total", ariaLabelledby "order-line-total" ]
      [ text <| dollars (item.donation * (toFloat item.quantity)) ]
    , td [ class "donation", ariaLabelledby "order-donation" ]
      [ text <| dollars item.donation ]
    , td [ class "quantity" ]
      [ input
        [ size 5
        , value (item.input)
        , ariaLabelledby "order-quantity"
        , onInput (TypeAmount item.code)
        , onBlur (FinishAmount item.code)
        ] []
      ]
    , td [ class "code", ariaLabelledby "order-code" ]
      [ text item.code ]
    , td [ class "builds", ariaLabelledby "order-builds" ]
      [ ul [] <| List.map displayBuild item.build ]

    ]

displayMenuItem : MenuItem -> Html Msg
displayMenuItem item =
  li [ class "menu-item" ]
    [ button [ onClick (AddOne item.code) ]
      [ span [ class "menu-graphic" ] <| List.map buildImage item.build
      , span [ class "menu-code" ] [ text item.code ]
      , span [ class "menu-donation" ] [ text <| dollars item.donation ]
      ]
    ]

buildImage : BuildItem -> Html Msg
buildImage build =
  if String.isEmpty build.image then
    strong [ class "menu-text" ] [ text <| quantityName build ]
  else
    img
      [ src build.image
      , alt <| quantityName build
      , title <| quantityName build
      , width 60
      , height 60
      ] []

displayBuild : BuildItem -> Html Msg
displayBuild build =
  li [ class "build" ] [ text <| quantityName build ]

quantityName : BuildItem -> String
quantityName build =
  (toString build.quantity)++" "++build.display_name

donationTotal : List OrderItem -> Float
donationTotal items =
  List.map (\i -> (toFloat i.quantity) * i.donation) items |> List.sum

donationText model =
  if String.length (donationTextLong model) < characterLimit then
    donationTextLong model
  else
    donationTextShort model

donationHeader model =
    String.join ", " <| List.filter (not << String.isEmpty) [ model.player, model.planet, model.round ]

--donationText : Model -> String
donationTextLong model =
  String.join ""
    [ donationHeader model
    , "\n"
    , orderTextLong <| nonZero model.selections
    ]

orderTextLong : List OrderItem -> String
orderTextLong items =
  List.map itemTextLong items |> String.join "\n"

itemTextLong : OrderItem -> String
itemTextLong item =
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

donationTextShort model =
  String.join ""
    [ donationHeader model
    , "\n"
    , orderTextShort <| nonZero model.selections
    ]

orderTextShort : List OrderItem -> String
orderTextShort items =
  List.map itemTextShort items |> String.join "\n"

itemTextShort : OrderItem -> String
itemTextShort item =
  String.join ""
    [ item.code
    , " x"
    , toString item.quantity
    ]

nonZero : List OrderItem -> List OrderItem
nonZero =
  List.filter (\i -> i.quantity > 0)

dollars : Float -> String
dollars n =
  "$"++(toString n)
