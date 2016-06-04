#!/usr/bin/env node
# Init requireJS
requirejs = require "./configure-requirejs"

debug     = require('debug')('index')
http      = require 'http'
websocket = require 'websocket'
PohnyApp  = requirejs './pohny-app'
TwilioApp = requirejs './twilio-app'

normalizePort = (val) ->
  ret = false
  port = parseInt(val, 10)
  if isNaN(port) then ret = val
  if port >= 0 then ret = port
  return ret


onError = (error) ->
  if error.syscall != 'listen' then throw error
  bind = if typeof port == 'string' then 'Pipe ' + port else 'Port ' + port
  # handle specific listen errors with friendly messages
  switch error.code
    when 'EACCES'
      console.error(bind + ' requires elevated privileges')
      process.exit(1)
    when 'EADDRINUSE'
      console.error(bind + ' is already in use')
      process.exit(1)
    else
      throw error

onListening = () ->
  addr = server.address()
  bind = if typeof addr == 'string' then 'pipe ' + addr else 'port ' + addr.port
  debug('Listening on ' + bind)


port = normalizePort(process.env.TWILIO_PORT || '3000')
app = requirejs './twilio-app'
app.set('port', port)

if app.get('env') == 'prod'
  process.on 'uncaughtException', (err) ->
    console.log 'Uncaught exception', err

server = http.createServer(app)

# Start websocket server on top of http
wsServer = new websocket.server({
  httpServer: server,
})
wsServer.on 'request', (request) ->
  try app.handleSocketRequest request
  catch e
    if e instanceof Error
      console.log(if app.get('env') == 'prod' then e else e.stack)
    else
      console.log e

server.listen(port)
server.on('error', onError)
server.on('listening', onListening)
