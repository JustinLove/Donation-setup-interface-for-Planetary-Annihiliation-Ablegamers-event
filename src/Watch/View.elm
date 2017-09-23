module Watch.View exposing (view, RoundSelection(..), HighlightColor(..), WVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onCheck, onSubmit, onInput)

type RoundSelection
  = AllRounds
  | Round String

type HighlightColor
  = Grey
  | Red
  | Green
  | Blue
  | Cyan
  | Magenta
  | Yellow

listOfColors =
  [ Grey
  , Red
  , Green
  , Blue
  , Cyan
  , Magenta
  , Yellow
  ]

type WVMsg
  = FilterRound RoundSelection
  | HighlightRound String HighlightColor
  | None

-- VIEW

--view : Model -> Html WVMsg
view model =
  div []
    [ div []
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
      , Html.form [ onSubmit None, class "row" ]
        [ div [ class "filtering-section col" ] <| filteringSection model
        , div [ class "highlighting-section col" ] <| highlightingSection model
        ]
      ]
      , donationsList <| List.reverse model.donations
    ]

filteringSection model =
  [ div [ class "row" ]
    [ div [ class "filtering-header col" ]
      [ fieldset []
        [ legend [] [ text "Filter" ]
        , select
          [ Html.Attributes.name "game"
          , onInput filterMessage 
          ]
          <| (allHeader model.round) :: (List.map (tabHeader model.round)
          <| (List.sortBy .name) model.rounds)
        ]
      ]
    ]
  ]

filterMessage : String -> WVMsg
filterMessage val =
  if val == "all" then
    FilterRound AllRounds
  else
    FilterRound (Round val)

allHeader : RoundSelection -> Html WVMsg
allHeader current =
  option [ value "all", selected (current == AllRounds) ] [ text "all" ] 

tabHeader : RoundSelection -> GameInfo -> Html WVMsg
tabHeader current round =
  option [ value round.id, selected (isCurrent current round) ] [ text round.id ] 

isCurrent : RoundSelection -> GameInfo -> Bool
isCurrent current round =
  case current of
    AllRounds -> False
    Round id -> id == round.id

highlightingSection model =
  [ div [ class "row" ]
    [ div [ class "highlighting-header col" ]
      [ fieldset []
        [ legend [] [ text "Highlight" ]
        , ul [ class "rounds", class "row" ]
          <| List.map highlightBox
          <| (List.sortBy .name) model.rounds
        ]
      ]
    ]
  ]

highlightBox : GameInfo -> Html WVMsg
highlightBox round =
  li [ class "col" ]
    [ label [ class "round-title" ] [ text round.id ]
    , ul [ class "colors" ] (List.map (colorChoice round) listOfColors)
    ]

colorChoice : GameInfo -> HighlightColor -> Html WVMsg
colorChoice round color =
  let
    colorName = colorNames color
    name = round.id ++ "-color"
    sel = False
    val = round.id ++ "-" ++ colorName
    lab = colorName
  in
    radioChoice (\_ -> None) name sel val lab colorName

colorNames : HighlightColor -> String
colorNames color =
  case color of
    Grey -> "grey"
    Red -> "red"
    Green -> "green"
    Blue -> "blue"
    Cyan -> "cyan"
    Magenta -> "magenta"
    Yellow -> "yellow"

radioChoice : (Bool -> WVMsg) -> String -> Bool -> String -> String -> String -> Html WVMsg
radioChoice msg name sel val lab color =
  li
    [ classList [ ("selected", sel), (color, True) ]
    ]
    [ input [type_ "radio", Html.Attributes.name name, id val, value val, onCheck msg, checked sel] []
    , label [ for val ] [text lab]
    ]

donationsList : List Donation -> Html WVMsg
donationsList donations =
  div [ class "row col" ]
    [ ul [ class "donations" ] <| List.map displayDonation donations
    ]

displayDonation : Donation -> Html WVMsg
displayDonation donation =
  li [ classList
      [ ("donation-item", True)
      , ("insufficient", donation.insufficient)
      , ("unaccounted", donation.unaccounted)
      ]
    ]
    [ p []
      [ span [ class "donor_name" ] [ text donation.donor_name ]
      , text " "
      , span [ class "amount" ] [ text <| "$" ++ (toString donation.amount) ]
      , text " "
      , span [ class "minimum" ] [ text <| "$" ++ (toString donation.minimum) ]
      ]
    , p [] (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
    , p [ class "comment" ] [ text donation.comment ]
    ]
