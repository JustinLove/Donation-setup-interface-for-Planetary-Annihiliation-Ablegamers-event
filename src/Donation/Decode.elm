module Donation.Decode exposing (donations, donation)

import Donation exposing (Donation)

import Json.Decode exposing (..)

donations : Decoder (List Donation)
donations =
  (field "donations" (list donation))

donation : Decoder Donation
donation =
  map10 Donation
    (field "amount" float)
    (field "comment" string)
    (field "donor_name" string)
    (field "donor_image" string)
    (field "discount_level" int)
    (field "id" int)
    (field "matchingMatches" (list string))
    (field "minimum" float)
    (field "insufficient" bool)
    (field "unaccounted" bool)

map9 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder h -> Decoder i -> Decoder value
map9 con a b c d e f g h i =
  a |> andThen (\da -> map8 (con da) b c d e f g h i)

map10 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> value) -> Decoder a -> Decoder b -> Decoder c -> Decoder d -> Decoder e -> Decoder f -> Decoder g -> Decoder h -> Decoder i -> Decoder j -> Decoder value
map10 con a b c d e f g h i j =
  a |> andThen (\da -> map9 (con da) b c d e f g h i j)

