module Watch.View exposing (view, RoundSelection(..), WVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onCheck, onSubmit)

type RoundSelection
  = AllRounds
  | Round String

type WVMsg
  = ChooseRound RoundSelection
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
        ]
      ]
      , donationsList model.donations
    ]

filteringSection model =
  [ div [ class "row" ]
    [ div [ class "rounds-header col" ]
      [ fieldset []
        [ legend [] [ text "Games" ]
        , ul [] <| (allHeader model.round) :: (List.map (tabHeader model.round) <| (List.sortBy .name) model.rounds)
        ]
      ]
    ]
  ]

allHeader : RoundSelection -> Html WVMsg
allHeader current =
  radioChoice (\_ -> ChooseRound AllRounds) "game" (current == AllRounds) "all" "all"

tabHeader : RoundSelection -> GameInfo -> Html WVMsg
tabHeader current round =
  radioChoice (\_ -> ChooseRound (Round round.id)) "game" (isCurrent current round) round.id round.id

isCurrent : RoundSelection -> GameInfo -> Bool
isCurrent current round =
  case current of
    AllRounds -> False
    Round id -> id == round.id

radioChoice : (Bool -> WVMsg) -> String -> Bool -> String -> String -> Html WVMsg
radioChoice msg name sel val lab =
  li []
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
  li [ class "donation" ]
    [ p []
      [ span [ class "donor-name" ] [ text donation.donor_name ]
      , span [ class "amount" ] [ text (toString donation.amount) ]
      ]
    , p [] (List.map text donation.matchingMatches)
    , p [ class "comment" ] [ text donation.comment ]
    ]
