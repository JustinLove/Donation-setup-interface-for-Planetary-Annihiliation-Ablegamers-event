module DonationConfig.Msg exposing (Msg(..))

import Menu exposing (MenuItem)
import GameInfo exposing (Options)
import PortSocket

import Http
import Time exposing (Posix)

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | Hover (Maybe MenuItem)
  | SetPlayer String
  | SetPlanet String
  | ChooseRound String
  | Select String
  | Instructions Bool
  | GotGameInfo (Result Http.Error Options)
  | SocketEvent PortSocket.Id PortSocket.Event
  | Reconnect String Posix
  | None
