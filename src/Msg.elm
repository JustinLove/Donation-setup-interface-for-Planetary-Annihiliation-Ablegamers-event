module Msg exposing (Msg(..))

import GameInfo exposing (GameInfo)
import Http

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | SetPlayer String
  | SetPlanet String
  | GotGameInfo (Result Http.Error (List GameInfo))
  | ChooseRound String
  | Select String
  | Instructions Bool
  | None
