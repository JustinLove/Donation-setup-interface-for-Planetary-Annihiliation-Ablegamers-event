module Msg exposing (Msg(..))

import GameInfo exposing (GameInfo)
import Http

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | SetPlayer String
  | GotGameInfo GameInfo
  | FetchError Http.Error
