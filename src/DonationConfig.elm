module DonationConfig exposing (main, init, update, view, subscriptions, DCMsg, Model, Arguments)

import DonationConfig.View
import DonationConfig.Msg exposing (..)
import Menu exposing (..)
import GameInfo exposing (Options, GameInfo) 
import GameInfo.Decode
import Config exposing (config) 
import DonationConfig.Harbor exposing (..) 

import Browser
import Http
import Regex
import String
import Array exposing (Array)
--import WebSocket
import Json.Decode

view = DonationConfig.View.view
type alias DCMsg = Msg

type alias Arguments =
  { menu: List RawMenuItem
  , info: List UnitInfo
  }

main : Program Arguments Model Msg
main =
  Browser.document
    { init = init
    , view = DonationConfig.View.document identity
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { rawMenu : List RawMenuItem
  , menu : List MenuItem
  , unitInfo: List UnitInfo
  , rounds: List GameInfo
  , round: String
  , player: String
  , planet: String
  , selections : List OrderItem
  , hover: Maybe MenuItem
  , instructionsOpen: Bool
  }

makeModel : List RawMenuItem -> List UnitInfo -> Model
makeModel menu info =
  let
    m2 = cook 0 info menu
  in
    { rawMenu = menu
    , menu = m2
    , unitInfo = info
    , rounds = []
    , round = ""
    , player = ""
    , planet = ""
    , selections = List.map makeOrder m2
    , hover = Nothing
    , instructionsOpen = False
    }

init : Arguments -> (Model, Cmd Msg)
init args =
  ( makeModel args.menu args.info
  , fetchGame
  )

fetchGame : Cmd Msg
fetchGame =
  Http.get
    { url = config.server ++ "options.json"
    , expect = Http.expectJson mapError GameInfo.Decode.options
    }

mapError : (Result Http.Error Options) -> Msg
mapError =
  Result.mapError Debug.toString
    >> GotGameInfo

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TypeAmount code number ->
      (updateOrder (updateInput number) code model, Cmd.none)
    FinishAmount code ->
      (updateOrder updateQuantity code model, Cmd.none)
    AddOne code ->
      (updateOrder addOne code model, Cmd.none)
    Hover item ->
      ({ model | hover = item }, Cmd.none)
    SetPlayer name ->
      ({ model | player = name}, Cmd.none)
    SetPlanet name ->
      ({ model | planet = name}, Cmd.none)
    ChooseRound id ->
      (updateDiscounts { model | round = id}, Cmd.none)
    GotGameInfo (Ok options) ->
      (updateDiscounts { model | rounds = options.games}, Cmd.none)
    GotGameInfo (Err err) ->
      let _ = Debug.log "error" err in
      (model, Cmd.none)
    Select id ->
      (model, select id)
    Instructions open ->
      ({model | instructionsOpen = open}, focus <| instructionFocus open)
    None ->
      (model, Cmd.none)

updateOrder : (OrderItem -> OrderItem) -> String -> Model -> Model
updateOrder f code model =
  { model | selections = List.map
      (\i -> if i.code == code then f i else i)
      model.selections
  }

updateInput : String -> OrderItem -> OrderItem
updateInput number item =
  { item | input = number }

updateQuantity : OrderItem -> OrderItem
updateQuantity item =
  if validNumber item.input then
    { item | quantity = getNumber item.input }
  else
    { item | quantity = 0, input = "" }

addOne : OrderItem -> OrderItem
addOne item =
  { item | quantity = item.quantity + 1, input = String.fromInt (item.quantity + 1) }

getNumber : String -> Int
getNumber s =
  String.toInt s |> Maybe.withDefault 0

validNumber : String -> Bool
validNumber value =
  Regex.contains onlyNumber value

onlyNumber : Regex.Regex
onlyNumber =
  "^\\d+$"
    |> Regex.fromString
    |> Maybe.withDefault Regex.never

updateDiscounts : Model -> Model
updateDiscounts model =
  let discountLevel = currentDiscountLevel model in 
    { model
    | menu = cook discountLevel model.unitInfo model.rawMenu
    , selections = List.map (updateOrderDiscounts discountLevel) model.selections
    }

updateOrderDiscounts : Int -> OrderItem -> OrderItem
updateOrderDiscounts discountLevel item =
  { item | donation = item.discounts
    |> Array.get (min discountLevel ((Array.length item.discounts) - 1))
    |> Maybe.withDefault item.donation
  }

currentDiscountLevel : Model -> Int
currentDiscountLevel model =
  model.rounds
  |> List.filterMap (\round -> if model.round == round.id then
                              Just round.discountLevel
                            else
                              Nothing)
  |> List.head
  |> Maybe.withDefault 0

instructionFocus : Bool -> String
instructionFocus open =
  if open then
    "#navigate-donation"
  else
    "#open-instructions"

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  --WebSocket.listen (config.wsserver ++ "options.json") receiveOptions
  Sub.none

receiveOptions : String -> Msg
receiveOptions message =
  Json.Decode.decodeString GameInfo.Decode.options message
    |> Result.mapError Debug.toString
    |> GotGameInfo
