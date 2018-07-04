module DonationConfig.Msg exposing (Msg(..))
import Menu exposing (MenuItem)

import GameInfo exposing (Options)
import Http

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | Hover (Maybe MenuItem)
  | SetPlayer String
  | SetPlanet String
  | GotGameInfo (Result String Options)
  | ChooseRound String
  | Select String
  | Instructions Bool
  | None
