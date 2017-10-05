module Msg exposing (Msg(..))

import GameInfo exposing (Options)
import Http

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | SetPlayer String
  | SetPlanet String
  | GotGameInfo (Result Http.Error Options)
  | ChooseRound String
  | Select String
  | Instructions Bool
  | None
