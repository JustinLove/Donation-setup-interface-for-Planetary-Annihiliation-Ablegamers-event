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
  | SetGameTime String String
  | SetDiscountLevel String String
  | EditDonation Donation
  | CommentChange String
  | DiscountLevelChange String
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
    , text " game time: "
    , input
      [ type_ "number"
      , Html.Attributes.min "0"
      , value (round.gameTime |> String.fromInt)
      , onInput (SetGameTime round.id)
      ] []
    , text " discount level: "
    , input
      [ type_ "number"
      , Html.Attributes.min "0"
      , value (round.discountLevel |> String.toInt)
      , onInput (SetDiscountLevel round.id)
      ] []
    ]

displayEditing : Donation -> DonationEdit -> Html AVMsg
displayEditing original edit =
  case edit of 
    NotEditing -> li [] []
    Editing edited  ->
      li []
        [ p []
          <| List.intersperse (text " ")
          [ span [ class "donor_name" ] [ text edited.donor_name ]
          , span [ class "amount" ] [ text <| "$" ++ (String.fromFloat edited.amount) ]
          , span [ class "minimum" ] [ text <| "$" ++ (String.fromFloat edited.minimum) ]
          , text " discount level: "
          , input
            [ type_ "number"
            , Html.Attributes.min "0"
            , value (edited.discount_level |> String.fromInt)
            , onInput DiscountLevelChange
            ] []
          ]
        , p []
          <| List.intersperse (text " ")
          <| List.concat
          [ tagList "player" edited.matchingPlayers
          , tagList "planet" edited.matchingPlanets
          , tagList "match" edited.matchingMatches
          , tagList "code-tag" edited.codes
          ]
        , p [ class "comment" ] [ text original.comment ]
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
        displayEditing donation edit
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
      , span [ class "amount" ] [ text <| "$" ++ (String.fromFloat donation.amount) ]
      , span [ class "minimum" ] [ text <| "$" ++ (String.fromFloat donation.minimum) ]
      , if donation.discount_level == 0 then
          text ""
        else
          span [ class "discount_level" ] [ text <| "(" ++ (String.fromInt donation.discount_level) ++ ")" ]
      , span [] (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
      , span [ class "comment" ] [ text donation.comment ]
      ]
    ]
