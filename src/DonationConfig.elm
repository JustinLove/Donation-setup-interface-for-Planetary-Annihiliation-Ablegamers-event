--import Menu exposing (..)

import Html exposing (Html, button, div, text, ul, li)
import Html.App
import Html.Events exposing (onClick)
import Http
import Task
import Regex exposing (regex)

main : Program (List MenuItem)
main =
  Html.App.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { menu : List MenuItem
  , selections : List MenuItem
  }

type alias MenuItem =
  { donation: Float
  , code: String
  , build: List BuildItem
  }
type alias BuildItem = (Int, String)

model : List MenuItem -> Model
model menu =
  { menu = menu
  , selections = []
  }

init : List MenuItem -> (Model, Cmd Msg)
init menu =
  ( model menu
  , Cmd.none
  )


-- UPDATE

type Msg
  = Noop

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Noop ->
      (model, Cmd.none)

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ ul [] <| List.map displayItem model.menu
    ]

displayItem : MenuItem -> Html Msg
displayItem item =
  li []
    [ text "$"
    , text <| toString item.donation
    , text " "
    , text <| item.code
    , ul [] <| List.map displayBuild item.build
    ]

displayBuild : BuildItem -> Html Msg
displayBuild (n,spec) =
  li []
    [ text <| toString n
    , text " "
    , text <| spec
    ]

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

