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
  | CancelEditing

type DonationEdit
  = NotEditing
  | Editing Donation

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
    Editing edited  ->
      li []
        [ p []
          <| List.intersperse (text " ")
          [ span [ class "donor_name" ] [ text edited.donor_name ]
          , span [ class "amount" ] [ text <| "$" ++ (toString edited.amount) ]
          , span [ class "minimum" ] [ text <| "$" ++ (toString edited.minimum) ]
          , if edited.discount_level == 0 then
              text ""
            else
              span [ class "discount_level" ] [ text <| "(" ++ (toString edited.discount_level) ++ ")" ]
          ]
        , p []
          <| List.intersperse (text " ")
          <| List.concat
          [ tagList "player" edited.matchingPlayers
          , tagList "planet" edited.matchingPlanets
          , tagList "match" edited.matchingMatches
          ]
        , p [ class "comment" ] [ text edited.comment ]
        , textarea [ onInput CommentChange, rows 5, cols 66 ] [ text edited.comment ]
        , p []
          [ Html.button [ onClick DoneEditing ] [ text "Done" ]
          , Html.button [ onClick CancelEditing ] [ text "Cancel" ]
          ]
        ]

tagList : String -> List String -> List (Html AVMsg)
tagList kind items =
  List.map (span [ class kind ] << List.singleton << text) <| items

displayDonation : DonationEdit -> Donation -> Html AVMsg
displayDonation edit donation =
  case edit of 
    NotEditing -> displayDonationOnly donation
    Editing edited ->
      if donation.id == edited.id then
        displayEditing edit
      else
        displayDonationOnly donation

displayDonationOnly : Donation -> Html AVMsg
displayDonationOnly donation =
  li
    [ classList
      [ ("donation-item", True)
      , ("insufficient", donation.insufficient)
      , ("unaccounted", donation.unaccounted)
      ]
    ]
    [ p []
      <| List.intersperse (text " ")

      [ Html.button [ onClick (EditDonation donation) ] [ text "Edit" ]
      , span [ class "donor_name" ] [ text donation.donor_name ]
      , span [ class "amount" ] [ text <| "$" ++ (toString donation.amount) ]
      , span [ class "minimum" ] [ text <| "$" ++ (toString donation.minimum) ]
      , if donation.discount_level == 0 then
          text ""
        else
          span [ class "discount_level" ] [ text <| "(" ++ (toString donation.discount_level) ++ ")" ]
      , span [] (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
      , span [ class "comment" ] [ text donation.comment ]
      ]
    ]
