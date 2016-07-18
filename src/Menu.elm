module Menu exposing (OrderItem, RawMenuItem, RawBuildItem, MenuItem, BuildItem, UnitInfo, cook, makeOrder)

import Regex exposing (regex)

type alias OrderItem =
  { donation: Float
  , code: String
  , build: List BuildItem
  , quantity: Int
  , input: String
  }

type alias MenuItem =
  { donation: Float
  , code: String
  , build: List BuildItem
  }

type alias BuildItem = 
  { spec: String
  , display_name: String
  , image: String
  , quantity: Int
  }

type alias RawMenuItem =
  { donation: Float
  , code: String
  , build: List RawBuildItem
  }

type alias RawBuildItem = (Int, String)

type alias UnitInfo = 
  { spec: String
  , display_name: String
  }

makeOrder : MenuItem -> OrderItem
makeOrder item =
  { donation = item.donation
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
          (List.sum (List.map fst match), spec) :: (compressBuilds other)
    _ -> builds

unitFor : List UnitInfo -> String -> Maybe UnitInfo
unitFor info spec =
  List.filter (\u -> u.spec == spec)info |> List.head

cook : List UnitInfo -> List RawMenuItem -> List MenuItem
cook info =
  List.map (cookMenuItem info)

cookMenuItem : List UnitInfo -> RawMenuItem -> MenuItem
cookMenuItem info item =
  { donation = item.donation
  , code = item.code
  , build = cookBuilds info item.build
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
      , image = Regex.replace Regex.All (regex "\\.json") (\_ -> ".png") spec
      , quantity = n
      }
    Nothing ->
      { spec = spec
      , display_name = spec
      , image = ""
      , quantity = n
      }
