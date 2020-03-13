module DonationConfig.Msg exposing (Msg(..), HoverTarget(..))

import Menu exposing (MenuItem)
import GameInfo exposing (Options)
import PortSocket
import Profile exposing (Profile)

import Http
import Time exposing (Posix)

type Msg
  = TypeAmount String String
  | FinishAmount String
  | AddOne String
  | RemoveAll String
  | Hover HoverTarget
  | SetPlayer String
  | SetPlanet String
  | ChooseRound String
  | Select String
  | Instructions Bool
  | GotGameInfo (Result Http.Error Options)
  | GotProfiles (Result Http.Error (List Profile))
  | SocketEvent PortSocket.Id PortSocket.Event
  | Reconnect String Posix
  | None

type HoverTarget
  = HoverNone
  | HoverItem MenuItem
  | HoverPlayer String
