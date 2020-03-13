module Profile.Decode exposing (profile, profiles)

import Profile exposing (Profile)

import Json.Decode exposing (..)

profiles : Decoder (List Profile)
profiles =
  (field "profiles" (list profile))

profile : Decoder Profile
profile =
  map3 Profile
    (field "name" string)
    (field "tagline" string)
    (field "cta" string)
