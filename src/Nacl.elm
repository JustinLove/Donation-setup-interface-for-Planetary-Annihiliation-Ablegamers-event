port module Nacl exposing (..)

type alias SignArguments =
  { method : String
  , url : String
  , id : String
  , key : String
  , body : String
  }

port signMessage : SignArguments -> Cmd msg
port signedMessage : (SignArguments -> msg) -> Sub msg
