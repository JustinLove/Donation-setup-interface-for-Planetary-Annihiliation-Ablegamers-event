module Admin.View exposing (view, AVMsg(..))
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

-- VIEW

--view : Model -> Html Msg
view model =
  div []
    [ p [] [ text config.server ]
    , textarea [ onInput SetKey, rows 3, cols 66 ] [ text model.signsk ]
    , ul [] <| List.map displayRound <| (List.sortBy .name) model.rounds
    , Html.button [ onClick ClearDonations ] [ text "Clear Donations" ]
    , ul [] <| List.map displayDonation <| List.reverse model.donations
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

displayDonation : Donation -> Html AVMsg
displayDonation donation =
  li [ classList
       [ ("donation-item", True)
       , ("insufficient", donation.insufficient)
       , ("unaccounted", donation.unaccounted)
       ]
     ]
     [ p [] <|
       List.concat
       [ [ span [ class "donor_name" ] [ text donation.donor_name ]
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
       , [ span [ class "comment" ] [ text donation.comment ] ]
       ]
     ]
