module Donation exposing (Donation, donations)

import Json.Decode exposing (..)

type alias Donation =
  { amount: Float
  , comment: String
  , donor_name: String
  , donor_image: String
  , id: Int
  , matchingMatches: List String
  , minimum: Float
  , insufficient: Bool
  , unaccounted: Bool
  }

donations : Decoder (List Donation)
donations =
  (field "donations" (list donation))

donation : Decoder Donation
donation =
  map9 Donation
    (field "amount" float)
    (field "comment" string)
    (field "donor_name" string)
    (field "donor_image" string)
    (field "id" int)
    (field "matchingMatches" (list string))
    (field "minimum" float)
    (field "insufficient" bool)
    (field "unaccounted" bool)

map9 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder h -> Decoder i -> Decoder value
map9 con a b c d e f g h i =
  a |> andThen (\da -> map8 (con da) b c d e f g h i)

