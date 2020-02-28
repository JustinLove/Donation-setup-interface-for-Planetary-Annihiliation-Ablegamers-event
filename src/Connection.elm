module Connection exposing (Status(..), connect, currentId, socketConnecting, socketClosed, socketReconnect)

import PortSocket

type Status
  = Disconnected
  | Connect Float
  | Connecting PortSocket.Id Float
  | Connected PortSocket.Id

initialReconnectDelay = 1000

connect : Status
connect = Connect initialReconnectDelay

closeIfCurrent : Status -> PortSocket.Id -> PortSocket.Id -> Status
closeIfCurrent connection id wasId =
  if id == wasId then
    Connect initialReconnectDelay
  else
    connection

currentId : Status -> Maybe PortSocket.Id
currentId connection =
  case connection of
    Disconnected ->
      Nothing
    Connect _ ->
      Nothing
    Connecting id _ ->
      Just id
    Connected id ->
      Just id


socketConnecting : PortSocket.Id -> String -> Status -> (Status, Cmd msg)
socketConnecting id url connection =
  ( case connection of
      Connect timeout -> Connecting id timeout
      Connecting _ timeout -> Connecting id timeout
      _ -> Connecting id initialReconnectDelay
  , currentId connection
      |> Maybe.map PortSocket.close
      |> Maybe.withDefault Cmd.none
  )

socketClosed : PortSocket.Id -> Status -> Status
socketClosed id connection =
  currentId connection
    |> Maybe.map (closeIfCurrent connection id)
    |> Maybe.withDefault connection

socketReconnect : String -> Status -> (Status, Cmd msg)
socketReconnect url connection =
  case Debug.log "reconnect" connection of
    Connect timeout ->
      ( Connect (timeout*2)
      , PortSocket.connect url
      )
    Connecting id timeout ->
      ( Connect (timeout*2)
      , Cmd.batch
        [ PortSocket.close id
        , PortSocket.connect url
        ]
      )
    _ ->
      (connection, Cmd.none)

