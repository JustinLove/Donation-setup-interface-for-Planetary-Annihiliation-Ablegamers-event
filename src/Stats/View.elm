module Stats.View exposing (document, view, SVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)
import Menu exposing (MenuItem, BuildItem)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick)

type SVMsg
  = None
  | SelectItem MenuItem

-- VIEW

--document : (SVMsg -> Msg) -> Model -> Browser.Document Msg
document tagger model =
  { title = "Stats"
  , body = [view model |> Html.map tagger]
  }

--view : Model -> Html SVMsg
view model =
  div [ class "row" ]
    [ model.menu
      |> List.map (displayMenuItem model.donations model.selectedItem)
      |> (::) statsHeader
      |> ul [ class "col stats" ]
    ]

statsHeader : Html SVMsg
statsHeader =
  li [ class "row stats-header" ]
    [ span [ class "col stats-graphic" ] []
    , span [ class "col stats-donation" ] [ text "dntn" ]
    , span [ class "col stats-code" ] [ text "code" ]
    , span [ class "col stats-times" ] [ text "times" ]
    , span [ class "col stats-total" ] [ text "total" ]
    , span [ class "col stats-raised" ] [ text "total $" ]
    ]

displayMenuItem : List Donation -> Maybe MenuItem -> MenuItem -> Html SVMsg
displayMenuItem allDonations current item =
  let 
    ourDonations =
      case item.code of
        "P1" ->
          allDonations
            |> List.filter (\d -> (overage d) > 0)
        "gift" ->
          allDonations
            |> List.filter (\d -> (gift d) > 0)
        _ -> 
          allDonations
            |> List.filter (\d -> (countOfCode item.code d) > 0)
    counts =
      case item.code of
        "P1" ->
          ourDonations
            |> List.map overage
        "gift" ->
          ourDonations
            |> List.map gift
        _ -> 
          ourDonations
            |> List.map (countOfCode item.code)
    times = List.length counts
    total = List.sum counts
    raised = (toFloat total) * item.donation
  in
  li [ class "row stats-item" ]
    [ button [ onClick (SelectItem item), class "row col" ]
      [ span [ class "col stats-graphic" ] <| List.map buildImage item.build
      , span [ class "col stats-donation" ] [ text <| dollars item.donation ]
      , span [ class "col stats-code" ] [ text item.code ]
      , span [ class "col stats-times" ] [ text <| String.fromInt times ]
      , span [ class "col stats-total" ] [ text <| String.fromInt total ]
      , span [ class "col stats-raised" ] [ text <| dollars raised ]
      ]
    , if Just item == current then
        ourDonations
          |> List.map displayDonation
          |> ul []
      else
        text ""
    ]

countOfCode : String -> Donation -> Int
countOfCode code donation =
  donation.codes
    |> List.filter (\c -> c == code)
    |> List.length

overage : Donation -> Int
overage donation =
  if List.length donation.codes == 0 then
    0
  else
    round (donation.amount - donation.minimum)

gift : Donation -> Int
gift donation =
  if List.length donation.codes == 0 then
    round donation.amount
  else
    0

buildImage : BuildItem -> Html SVMsg
buildImage build =
  if String.isEmpty build.image then
    strong [ class "stats-text" ] [ text <| quantityName build ]
  else
    img
      [ src build.image
      , alt <| quantityNameDescription build
      , title <| quantityNameDescription build
      , width 60
      , height 60
      ] []

displayDonation : Donation -> Html SVMsg
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
       , span [ class "amount" ] [ text <| "$" ++ (String.fromFloat donation.amount) ]
       , text " "
       , span [ class "minimum" ] [ text <| "$" ++ (String.fromFloat donation.minimum) ]
       ]
     , p [] (List.map (span [ class "match" ] << List.singleton << text) donation.matchingMatches)
     , p [ class "comment" ] [ text donation.comment ]
     ]

quantityName : BuildItem -> String
quantityName build =
  (String.fromInt build.quantity)++" "++build.display_name

quantityNameDescription : BuildItem -> String
quantityNameDescription build =
  (quantityName build) ++ " -- " ++ build.description

dollars : Float -> String
dollars n =
  "$"++(String.fromFloat n)
