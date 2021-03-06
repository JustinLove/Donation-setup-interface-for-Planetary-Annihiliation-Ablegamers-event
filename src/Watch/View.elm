module Watch.View exposing (document, view, RoundSelection(..), HighlightColor(..), WVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)

import Dict exposing (Dict)
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

--document : (WVMsg -> Msg) -> Model -> Browser.Document Msg
document tagger model =
  { title = "Donations"
  , body = [view model |> Html.map tagger]
  }

--view : Model -> Html WVMsg
view model =
  div []
    [ div []
      [ Html.form [ onSubmit None, class "row" ]
        [ div [ class "filtering-section col" ] <| filteringSection model
        , div [ class "highlighting-section col" ] <| highlightingSection model
        ]
      ]
    , model.donations
      |> List.filter (inMatch model.round)
      |> List.reverse
      |> donationsList model.roundColors
    ]

inMatch : RoundSelection -> Donation -> Bool
inMatch round donation =
  case round of
    AllRounds -> True
    Round id -> List.member id donation.matchingMatches

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
          <| List.map (highlightBox model.roundColors)
          <| (List.sortBy .name) model.rounds
        ]
      ]
    ]
  ]

highlightBox : Dict String HighlightColor -> GameInfo -> Html WVMsg
highlightBox roundColors round =
  li [ class "col" ]
    [ label [ class "round-title" ] [ text round.id ]
    , ul [ class "colors" ] (List.map (colorChoice round (lookupColor roundColors round.id)) listOfColors)
    ]

lookupColor : Dict String HighlightColor -> String -> HighlightColor
lookupColor roundColors id =
  case Dict.get id roundColors of
    Just color -> color
    Nothing -> Grey

colorChoice : GameInfo -> HighlightColor -> HighlightColor -> Html WVMsg
colorChoice round current color =
  let
    colorName = colorNames color
    name = round.id ++ "-color"
    sel = current == color
    val = round.id ++ "-" ++ colorName
    lab = colorName
  in
    radioChoice (\_ -> HighlightRound round.id color) name sel val lab colorName

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

donationsList : Dict String HighlightColor -> List Donation -> Html WVMsg
donationsList roundColors donations =
  div [ class "row col" ]
    [ ul [ class "donations" ] <| List.map (displayDonation roundColors) donations
    ]

displayDonation : Dict String HighlightColor -> Donation -> Html WVMsg
displayDonation roundColors donation =
  li [ classList
       (List.append
          [ ("donation-item", True)
          , ("insufficient", donation.insufficient)
          , ("unaccounted", donation.unaccounted)
          ]
          (List.map
            (lookupColor roundColors
            >> colorNames
            >> (\c -> (c, True)))
            donation.matchingMatches)
       )
     ]
     [ p []
       [ span [ class "donor_name" ] [ text donation.donor_name ]
       , text " "
       , span [ class "amount" ] [ text <| "$" ++ (String.fromFloat donation.amount) ]
       , text " "
       , span [ class "minimum" ] [ text <| "$" ++ (String.fromFloat donation.minimum) ]
       ]
     , p [] (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
     , p [ class "comment" ] [ text donation.comment ]
     ]
