module Msg exposing (Msg(..))

import GameInfo exposing (GameInfo)
import Http

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | SetPlayer String
  | SetPlanet String
  | GotGameInfo (List GameInfo)
  | FetchError Http.Error
  | ChooseRound String
  | None
