module Donation.Decode exposing (donations, donation)

import Donation exposing (Donation)

import Json.Decode exposing (..)

donations : Decoder (List Donation)
donations =
  (field "donations" (list donation))

donation : Decoder Donation
donation =
  succeed Donation
    |> set (field "amount" float)
    |> set (field "comment" string)
    |> set (field "donor_name" string)
    |> set (field "donor_image" string)
    |> set (field "discount_level" int)
    |> set (field "id" int)
    |> set (field "matchingMatches" (list string))
    |> set (oneOf [ (field "matchingPlayers" (list string)), succeed [] ])
    |> set (oneOf [ (field "matchingPlanets" (list string)), succeed [] ])
    |> set (field "minimum" float)
    |> set (field "insufficient" bool)
    |> set (field "unaccounted" bool)

set : Decoder a -> Decoder (a -> b) -> Decoder b
set decoder =
  andThen (\f -> map f decoder)
