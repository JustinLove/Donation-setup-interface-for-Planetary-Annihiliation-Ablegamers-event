module GameInfo exposing (Options, GameInfo)

type alias GameInfo =
  { name: String
  , id: String
  , players: List String
  , planets: List String
  , discountLevel : Int
  }

type alias Options =
  { games: List GameInfo
  }
