module Admin.View exposing (document, view, Editing(..), AVMsg(..))
import Config exposing (config) 
import GameInfo exposing (GameInfo) 
import Donation exposing (Donation)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (onClick, onInput)
import Set

type AVMsg
  = SetKey String
  | DeleteRound String
  | EditRound GameInfo
  | ClearDonations
  | SetGameTime String String
  | SetDiscountLevel String String
  | SetRoundName String
  | SetPlayerName Int String
  | SetPlanetName Int String
  | DeletePlayer Int
  | DeletePlanet Int
  | AddPlayer String
  | AddPlanet
  | EditDonation Donation
  | CommentChange String
  | DiscountLevelChange String
  | DoneEditing
  | CancelEditing
  | SetRoundId String
  | CopyRound

type Editing
  = NotEditing
  | EditingDonation Donation
  | EditingRound String GameInfo

-- VIEW

--document : (AVMsg -> Msg) -> Model -> Browser.Document Msg
document tagger model =
  { title = "Donation Admin"
  , body = [view model |> Html.map tagger]
  }

--view : Model -> Html Msg
view model =
  div []
    [ p [] [ text config.server ]
    , textarea [ onInput SetKey, rows 3, cols 66 ] [ text model.signsk ]
    , model.rounds
     |> (List.sortBy .name)
     |> List.map (displayRound (playerNames model.rounds) model.editing)
     |> (::) roundHeader
     |> table [] 
    , ul [] <| List.map (displayDonation model.editing) <| List.reverse model.donations
    , Html.button [ onClick ClearDonations ] [ text "Clear Donations" ]
    ]

roundHeader : Html AVMsg
roundHeader =
  tr []
    [ th [] [ text "Edit" ]
    , th [] [ text "game time" ]
    , th [] [ text "discount level" ]
    ]

displayRound : List String -> Editing -> GameInfo -> Html AVMsg
displayRound players edit round =
  case edit of 
    NotEditing -> displayRoundOnly round
    EditingDonation _ -> displayRoundOnly round
    EditingRound copyId edited ->
      if round.id == edited.id then
        displayEditingRound players copyId edited
      else
        displayRoundOnly round

displayRoundOnly : GameInfo -> Html AVMsg
displayRoundOnly round =
  tr []
    [ td []
      [ Html.button [ onClick (EditRound round) ]
        [ text round.name
        ]
      ]
    , td []
      [ input
        [ type_ "number"
        , Html.Attributes.min "0"
        , value (round.gameTime |> String.fromInt)
        , onInput (SetGameTime round.id)
        ] []
      ]
    , td []
      [ input
        [ type_ "number"
        , Html.Attributes.min "0"
        , value (round.discountLevel |> String.fromInt)
        , onInput (SetDiscountLevel round.id)
        ] []
      ]
    ]

displayEditingRound : List String -> String -> GameInfo -> Html AVMsg
displayEditingRound players copyId edited =
  tr []
    [ td [ colspan 3 ]
      [ p []
        <| List.intersperse (text " ")
        [ input
          [ type_ "text"
          , size 40
          , value edited.name
          , onInput SetRoundName
          ] []
        ]
      , div [ class "row" ]
        [ div [ class "players col" ]
          [ fieldset []
            [ legend [] [ text "Players" ]
            , edited.players 
              |> List.indexedMap displayPlayer
              |> listSuffix 
                  [ players
                    |> List.append ["+"]
                    |> listSuffix ["--"]
                    |> List.map text
                    |> List.map List.singleton
                    |> List.map (option [])
                    |> select [ onInput AddPlayer ]
                  ]
              |> ul []
            ]
          ]
        , div [ class "planets col" ]
          [ fieldset []
            [ legend [] [ text "Planets" ]
            , edited.planets
              |> List.indexedMap displayPlanet
              |> listSuffix 
                  [ Html.button [ onClick AddPlanet ]
                    [ text "+"
                    ]
                  ]
              |> ul []
            ]
          ]
        ]
      , p []
        [ Html.button [ onClick DoneEditing ] [ text "Done" ]
        , Html.button [ onClick CancelEditing ] [ text "Cancel" ]
        , Html.button [ onClick (DeleteRound edited.id) ] [ text "Delete" ]
        , Html.button [ onClick CopyRound ] [ text "Copy As" ]
        , input
          [ type_ "text"
          , size 10
          , value copyId
          , onInput SetRoundId
          ] []
        ]
      ]
    ]

displayPlayer : Int -> String -> Html AVMsg
displayPlayer index name =
  textEdit (SetPlayerName index) (DeletePlayer index) ((String.fromInt index) ++ "-player") name name

displayPlanet : Int -> String -> Html AVMsg
displayPlanet index name =
  textEdit (SetPlanetName index) (DeletePlanet index) ((String.fromInt index) ++ "-planet") name name

textEdit : (String -> AVMsg) -> AVMsg -> String -> String -> String -> Html AVMsg
textEdit edit delete name val lab =
  li []
    [ input
      [ type_ "text"
      , Html.Attributes.name name
      , id val
      , value val
      , onInput edit
      ] []
    , Html.button [ onClick delete ]
      [ text "X"
      ]
    ]

displayEditingDonation : Donation -> Donation -> Html AVMsg
displayEditingDonation original edited =
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

displayDonation : Editing -> Donation -> Html AVMsg
displayDonation edit donation =
  case edit of 
    NotEditing -> displayDonationOnly donation
    EditingRound _ _ -> displayDonationOnly donation
    EditingDonation edited ->
      if donation.id == edited.id then
        displayEditingDonation donation edited
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

listSuffix : List a -> List a -> List a
listSuffix suffix list =
  List.append list suffix

playerNames : List GameInfo -> List String
playerNames rounds =
  rounds
    |> List.concatMap .players
    |> Set.fromList
    |> Set.toList
