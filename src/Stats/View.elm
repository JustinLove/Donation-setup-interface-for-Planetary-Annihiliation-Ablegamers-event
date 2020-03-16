module Stats.View exposing (document, view, SVMsg(..))

import GameInfo exposing (GameInfo)
import Donation exposing (Donation)

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
  div []
    [
    ]

