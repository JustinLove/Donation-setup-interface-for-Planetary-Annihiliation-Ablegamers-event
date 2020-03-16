module Connection exposing (Status(..), connect, currentId, socketConnecting, socketClosed, socketReconnect, update, reconnect, keepAlive)

import PortSocket

import Time exposing (Posix)

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

update
  :  PortSocket.Id
  -> PortSocket.Event
  -> (String -> (Status -> (Status, Cmd msg)) -> model -> (model, Cmd msg))
  -> model
  -> (model, Cmd msg)
update id event updateConnection model =
  case event of
    (PortSocket.Error value) ->
      let _ = Debug.log "websocket error" value in
      (model, Cmd.none)
    (PortSocket.Connecting url) ->
      let _ = Debug.log "websocket connecting" id in
      updateConnection url (socketConnecting id url) model
    (PortSocket.Open url) ->
      let _ = Debug.log "websocket open" id in
      updateConnection url (always (Connected id, Cmd.none)) model
    (PortSocket.Close url) ->
      let _ = Debug.log "websocket closed" id in
      updateConnection url (\m -> (socketClosed id m, Cmd.none)) model
    (PortSocket.Message message) ->
      let _ = Debug.log "websocket id" id in
      let _ = Debug.log "websocket message" message in
      (model, Cmd.none)

reconnect : (Posix -> msg) -> Status -> Sub msg
reconnect tagger connection =
  case connection of
    Connect timeout-> Time.every timeout tagger
    Connecting _ timeout-> Time.every timeout tagger
    _ -> Sub.none

keepAlive : Float -> (PortSocket.Id -> Posix -> msg) -> Status -> Sub msg
keepAlive timeout tagger connection =
  case connection of
    Connected id -> Time.every timeout (tagger id)
    _ -> Sub.none
