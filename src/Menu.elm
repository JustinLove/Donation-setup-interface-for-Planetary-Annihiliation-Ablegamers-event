module Menu exposing (OrderItem, MenuItem, BuildItem, compress, makeOrder)

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

type alias BuildItem = (Int, String)

makeOrder : MenuItem -> OrderItem
makeOrder item =
  { donation = item.donation
  , code = item.code
  , build = item.build
  , quantity = 0
  , input = ""
  }

compress : List MenuItem -> List MenuItem
compress =
  List.map compressMenuItem

compressMenuItem : MenuItem -> MenuItem
compressMenuItem item =
  { item | build = compressBuilds item.build }

compressBuilds : List BuildItem -> List BuildItem
compressBuilds builds =
  case builds of
    (num, spec) :: tl ->
      case List.partition (\(n,s) -> s == spec) builds of
        (match, other) ->
          (List.sum (List.map fst match), spec) :: (compressBuilds other)
    _ -> builds
