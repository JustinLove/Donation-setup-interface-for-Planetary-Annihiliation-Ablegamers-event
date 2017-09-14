module Watch.View exposing (view, WVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onCheck, onSubmit)

type WVMsg
  = ChooseRound String
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
        , ul [] <| List.map (tabHeader model.round) <| (List.sortBy .name) model.rounds
        ]
      ]
    ]
  ]

radioChoice : (String -> WVMsg) -> String -> String -> String -> String -> Html WVMsg
radioChoice msg name current val lab =
  li []
    [ input [type_ "radio", Html.Attributes.name name, id val, value val, onCheck (\_ -> msg val), checked (val == current)] []
    , label [ for val ] [text lab]
    ]

tabHeader : String -> GameInfo -> Html WVMsg
tabHeader current round =
  radioChoice ChooseRound "game" current round.id round.id

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
