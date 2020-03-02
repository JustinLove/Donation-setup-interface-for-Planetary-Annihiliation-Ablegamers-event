module Menu exposing (OrderItem, RawMenuItem, RawBuildItem, MenuItem, BuildItem, UnitInfo, cook, makeOrder)

import String
import Tuple exposing (first)
import Array exposing (Array)

type alias OrderItem =
  { donation: Float
  , discounts : Array Float
  , code: String
  , build: List BuildItem
  , quantity: Int
  , input: String
  }

type alias MenuItem =
  { donation: Float
  , discounts : Array Float
  , code: String
  , build: List BuildItem
  }

type alias BuildItem = 
  { spec: String
  , display_name: String
  , description: String
  , image: String
  , quantity: Int
  }

type alias RawMenuItem =
  { code: String
  , donation: Float
  , discounts: Array Float
  , build: List RawBuildItem
  }

type alias RawBuildItem = (Int, String)

type alias UnitInfo = 
  { spec: String
  , display_name: String
  , description: String
  }

makeOrder : MenuItem -> OrderItem
makeOrder item =
  { donation = item.donation
  , discounts = item.discounts
  , code = item.code
  , build = item.build
  , quantity = 0
  , input = ""
  }

compress : List RawMenuItem -> List RawMenuItem
compress =
  List.map compressMenuItem

compressMenuItem : RawMenuItem -> RawMenuItem
compressMenuItem item =
  { item | build = compressBuilds item.build }

compressBuilds : List RawBuildItem -> List RawBuildItem
compressBuilds builds =
  case builds of
    (num, spec) :: tl ->
      case List.partition (\(n,s) -> s == spec) builds of
        (match, other) ->
          (List.sum (List.map first match), spec) :: (compressBuilds other)
    _ -> builds

unitFor : List UnitInfo -> String -> Maybe UnitInfo
unitFor info spec =
  List.filter (\u -> u.spec == spec)info |> List.head

cook : Int -> List UnitInfo -> List RawMenuItem -> List MenuItem
cook discountLevel info menu =
  List.append (List.map (cookMenuItem discountLevel info) menu) [priorityItem]

cookMenuItem : Int -> List UnitInfo -> RawMenuItem -> MenuItem
cookMenuItem discountLevel info item =
  { donation = item.discounts
    |> Array.get (min discountLevel ((Array.length item.discounts) - 1))
    |> Maybe.withDefault item.donation
  , discounts = item.discounts
  , code = item.code
  , build = cookBuilds info item.build
  }

priorityItem : MenuItem
priorityItem =
  { donation = 1
  , discounts = Array.fromList [1]
  , code = "P1"
  , build = [priorityBuild]
  }

cookBuilds : List UnitInfo -> List RawBuildItem -> List BuildItem
cookBuilds info build =
  List.map (cookBuildItem info) (compressBuilds build)

cookBuildItem : List UnitInfo -> RawBuildItem -> BuildItem
cookBuildItem info (n, spec) =
  case unitFor info spec of
    Just unit ->
      { spec = spec
      , display_name = unit.display_name
      , description = unit.description
      , image = imagePath spec
      , quantity = n
      }
    Nothing ->
      { spec = spec
      , display_name = spec
      , description = ""
      , image = ""
      , quantity = n
      }

priorityBuild : BuildItem
priorityBuild =
  { spec = ""
  , display_name = "Priority"
  , description = "Move your units up in the queue if donation execution is backlogged."
  , image = ""
  , quantity = 1
  }

imagePath : String -> String
imagePath s =
  if String.endsWith ".json" s then
    s
      |> String.dropRight 5
      |> (\x -> String.append x "_icon_buildbar.png")
  else
    s
