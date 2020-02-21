module Donation.Encode exposing (donation)

import Donation exposing (Donation)

import Json.Encode exposing (..)

donation : Donation -> Value
donation d =
  object
   [ ("amount", float d.amount)
   , ("comment", string d.comment)
   , ("donor_name", string d.donor_name)
   , ("donor_image", string d.donor_image)
   , ("discount_level", int d.discount_level)
   , ("id", int d.id)
   , ("matchingMatches", (list string d.matchingMatches))
   , ("minimum", float d.minimum)
   , ("insufficient", bool d.insufficient)
   , ("unaccounted", bool d.unaccounted)
   ]
