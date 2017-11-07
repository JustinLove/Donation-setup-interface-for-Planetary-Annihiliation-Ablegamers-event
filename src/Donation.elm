module Donation exposing (Donation)

type alias Donation =
  { amount: Float
  , comment: String
  , donor_name: String
  , donor_image: String
  , discount_level: Int
  , id: Int
  , matchingMatches: List String
  , matchingPlayers: List String
  , matchingPlanets: List String
  , minimum: Float
  , insufficient: Bool
  , unaccounted: Bool
  }
