#!/usr/bin/env node
# Init requireJS
requirejs = require "./configure-requirejs"

debug     = require('debug')('index')
http      = require 'http'
websocket = require 'websocket'
resources = requirejs './resources'
resources.init () ->
  pohnyApp  = requirejs('./pohny-app')(resources)
  twilioApp = requirejs('./twilio-app')(resources)

  if process.env.NODE_ENV == 'prod'
    process.on 'uncaughtException', (err) -> console.log 'Uncaught exception', err

  normalizePort = (val) ->
    ret = false
    port = parseInt(val, 10)
    if isNaN(port) then ret = val
    if port >= 0 then ret = port
    return ret

  onError = (error) ->
    if error.syscall != 'listen' then throw error
    bind = if typeof error.port == 'string' then 'Pipe ' + error.port else 'Port ' + error.port
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

  # INIT Twilio endpoints, http is used by twilio to notify you with message and calls
  process.env.TWILIO_PORT = 9876
  twilioPort = normalizePort(process.env.TWILIO_PORT || '3001')
  #twilioApp.set('port', twilioPort)
  twilioServer = http.createServer(twilioApp)

  twilioServer.listen twilioPort, () -> console.log((new Date()) + ' Server is listening on port ' + twilioPort)
  twilioServer.on('error', onError)
  #twilioServer.on('listening', onListening)


  # INIT Pohny endpoints, http and websocket for user
  pohnyPort = normalizePort(process.env.POHNY_PORT || '3000')
  # Create http server and listen on a specific port
  pohnyServer = http.createServer(pohnyApp.getHttpRequestHandler())
  # Start websocket server on top of http
  wsServer = new websocket.server({ httpServer: pohnyServer })
  wsServer.on 'request', (request) ->
    try pohnyApp.handleSocketRequest request
    catch e
      if e instanceof Error then console.log(if pohnyApp.get('env') == 'prod' then e else e.stack)
      else console.log e


  pohnyServer.listen pohnyPort, () -> console.log((new Date()) + ' Server is listening on port ' + pohnyPort)
  pohnyServer.on('error', onError)
  #pohnyServer.on('listening', onListening)
