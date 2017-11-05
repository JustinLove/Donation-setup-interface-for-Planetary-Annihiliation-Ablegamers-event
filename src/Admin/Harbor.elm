port module Admin.Harbor exposing (matchInDonation, matchedModel)

import Donation
import GameInfo

import Json.Decode

type alias MatchArguments =
  { rounds: List GameInfo.GameInfo
  , donation: Donation.Donation
  }

port matchInDonation : MatchArguments -> Cmd msg
port matchedModel : (Json.Decode.Value -> msg) -> Sub msg
