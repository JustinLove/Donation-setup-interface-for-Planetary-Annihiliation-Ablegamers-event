module Admin.View exposing (view, DonationEdit(..), AVMsg(..))
import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick, onInput)

type AVMsg
  = SetKey String
  | DeleteRound String
  | ClearDonations
  | SetDiscountLevel String String
  | EditDonation Donation
  | CommentChange String
  | DoneEditing

type DonationEdit
  = NotEditing
  | Editing Donation String

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ p [] [ text config.server ]
    , textarea [ onInput SetKey, rows 3, cols 66 ] [ text model.signsk ]
    , ul [] <| List.map displayRound <| (List.sortBy .name) model.rounds
    , ul [] <| List.map (displayDonation model.editing) <| List.reverse model.donations
    , Html.button [ onClick ClearDonations ] [ text "Clear Donations" ]
    ]

displayRound : GameInfo -> Html AVMsg
displayRound round =
  li []
    [ Html.button [ onClick (DeleteRound round.id) ]
      [ text "X "
      , text round.name
      ]
    , text " discount level: "
    , input
      [ type_ "number"
      , Html.Attributes.min "0"
      , value (round.discountLevel |> toString)
      , onInput (SetDiscountLevel round.id)
      ] []
    ]

displayEditing : DonationEdit -> Html AVMsg
displayEditing edit =
  case edit of 
    NotEditing -> li [] []
    Editing donation comment ->
      li []
        [ p [] 
          [ span [ class "donor_name" ] [ text donation.donor_name ]
          , text " "
          , span [ class "amount" ] [ text <| "$" ++ (toString donation.amount) ]
          ]
        , textarea [ onInput CommentChange, rows 5, cols 66 ] [ text comment ]
        , p [] [ Html.button [ onClick DoneEditing ] [ text "Done" ] ]
        ]

displayDonation : DonationEdit -> Donation -> Html AVMsg
displayDonation edit donation =
  case edit of 
    NotEditing -> displayDonationOnly donation
    Editing editing comment ->
      if donation.id == editing.id then
        displayEditing edit
      else
        displayDonationOnly donation

displayDonationOnly : Donation -> Html AVMsg
displayDonationOnly donation =
  li [ classList
       [ ("donation-item", True)
       , ("insufficient", donation.insufficient)
       , ("unaccounted", donation.unaccounted)
       ]
     ]
     [ p [] <|
       List.concat
       [ [ Html.button [ onClick (EditDonation donation) ] [ text "Edit" ]
         , text " "
         , span [ class "donor_name" ] [ text donation.donor_name ]
         , text " "
         , span [ class "amount" ] [ text <| "$" ++ (toString donation.amount) ]
         , text " "
         , span [ class "minimum" ] [ text <| "$" ++ (toString donation.minimum) ]
         , text " "
         , if donation.discount_level == 0 then
             text ""
           else
             span [ class "discount_level" ] [ text <| "(" ++ (toString donation.discount_level) ++ ")" ]
         , text " "
         ]
       , (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
       , [ text " ", span [ class "comment" ] [ text donation.comment ] ]
       ]
     ]
