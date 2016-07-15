module Msg exposing (Msg(..))

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | SetPlayer String
