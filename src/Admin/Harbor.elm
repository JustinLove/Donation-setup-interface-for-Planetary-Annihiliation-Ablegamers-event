port module Admin.Harbor exposing (matchInDonation, matchedModel)

import Json.Decode

port matchInDonation : Json.Decode.Value -> Cmd msg
port matchedModel : (Json.Decode.Value -> msg) -> Sub msg
