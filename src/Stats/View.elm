module Stats.View exposing (document, view, SVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)
import Menu exposing (MenuItem, BuildItem)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onCheck, onSubmit, onInput)

type SVMsg
  = None

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
      |> List.map (displayMenuItem model.donations)
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

displayMenuItem : List Donation -> MenuItem -> Html SVMsg
displayMenuItem allDonations item =
  let 
    ourDonations =
      allDonations
        |> List.map (countOfCode item.code)
        |> List.filter (\x -> x > 0)
    times = List.length ourDonations
    total = List.sum ourDonations
    raised = (toFloat total) * item.donation
  in
  li [ class "row stats-item" ]
    [ button [ ]
      [ span [ class "col stats-graphic" ] <| List.map buildImage item.build
      , span [ class "col stats-donation" ] [ text <| dollars item.donation ]
      , span [ class "col stats-code" ] [ text item.code ]
      , span [ class "col stats-times" ] [ text <| String.fromInt times ]
      , span [ class "col stats-total" ] [ text <| String.fromInt total ]
      , span [ class "col stats-raised" ] [ text <| dollars raised ]
      ]
    ]

countOfCode : String -> Donation -> Int
countOfCode code donation =
  donation.codes
    |> List.filter (\c -> c == code)
    |> List.length

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

quantityName : BuildItem -> String
quantityName build =
  (String.fromInt build.quantity)++" "++build.display_name

quantityNameDescription : BuildItem -> String
quantityNameDescription build =
  (quantityName build) ++ " -- " ++ build.description

dollars : Float -> String
dollars n =
  "$"++(String.fromFloat n)
