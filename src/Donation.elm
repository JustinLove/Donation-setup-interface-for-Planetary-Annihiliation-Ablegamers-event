module Donation exposing (Donation, donations)

import Json.Decode exposing (..)

type alias Donation =
  { amount: Float
  , comment: String
  , donor_name: String
  , donor_image: String
  , id: Int
  , matchingMatches: List String
  }

donations : Decoder (List Donation)
donations =
  (field "donations" (list donation))

donation : Decoder Donation
donation =
  map6 Donation
    (field "amount" float)
    (field "comment" string)
    (field "donor_name" string)
    (field "donor_image" string)
    (field "id" int)
    (field "matchingMatches" (list string))
