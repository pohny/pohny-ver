define (require, exports, module) ->
  return (resources) ->
    # TODO: maybe remove config, and manage everything with process.env
    debug     = require('debug')('app')
    JSONRPC   = require 'jsonrpc-simple'
    JSONRPC.DEBUG = true
    UserService   = require 'services/user-service'
    User          = require 'models/user'
    Conversation  = require 'models/conversation'
    resources     = require './resources'
    Promise       = require 'bluebird'
    DateHelper = require 'lib/date-helper'

    express = require 'express'
    logger  = require 'morgan'
    bodyParser  = require 'body-parser'
    path    = require 'path'

    #conversationMapper = resources.conversationMapper
    userMapper = resources.userMapper
    dataSource = resources.dataSource
    users = dataSource.users
    root = path.join( path.dirname(module.uri), '../')


    class App

      attrs: null
      get: (key) -> return @attrs[key]
      set: (key, value) -> @attrs[key] = value; return @

      constructor: () ->
        @attrs = {}
        @set('env', process.env.NODE_ENV || 'prod')
        @set('resources', resources)

        @connections =
          data: {}
          get: (userId) -> return @data[userId]
          set: (userId, connection) -> @data[userId] = connection
          #has: (userId) -> Boolean(@get(userId))

        @isConnected = (userId) ->
          connection = @connections.get(userId) || {}
          return Boolean(connection.connected)

      respond: (userId, response) ->
        if response instanceof Object == false then throw "Invalid response type, HashMap expected"
        connection = @connections.get(userId)
        if connection
          connection.send(JSON.stringify(response))

      sendOne: (userId, method, params, stackId) ->
        connection = @connections.get(userId)
        debug 'Send', method, userId, (if Boolean(connection) then true else connection)
        if connection
          data = { jsonrpc: "2.0", method: method, params: params }
          if stackId then data.id = stackId
          #debug '[' + userId + '] sent:', JSON.stringify(data)
          connection.send(JSON.stringify(data))

      sendMany: (data) ->
        for datum in data
          @sendOne.apply(@, datum)

      getHttpRequestHandler: () ->
        expressApp = express()
        env = expressApp.get 'env'
        authController = require('controllers/auth-controller')(@)
        twilioController = require('controllers/twilio-controller')(@)

        # 1. logger comes first to be able to log everything
        expressApp.use logger(if env != 'prod' then 'dev' else 'short')

        # 2. Classic express configuration
        if env == 'dev'
          expressApp.use express.static(path.join(root, 'public'))
        expressApp.use bodyParser.json()
        expressApp.use bodyParser.urlencoded({ extended: true})
        expressApp.use '/', authController
        expressApp.use '/', twilioController

        if env != 'prod'
          expressApp.get '/info', (req, res) =>
            dumpLocalDB = require 'lib/dump-local-db'
            #resources.respond res, 200, dumpLocalDB(resources.dataSource, @)
            #res.setHeader('content-type', 'text/plain')
            res.status(200).send dumpLocalDB(resources.dataSource, @)


      ### (public) Register connetion ###
      #getSocketRequestHandler: () ->
      handleSocketRequest: (request) ->
        debug "Connection attempt"
        connection = undefined
        userId = null
        Promise.try () ->
          userId = resources.authMiddleware request
          debug 'userId:', userId
          userMapper.get(userId)
        .then (user) =>
          #debug 'user:', user, resources.dataSource.users
          if !user then throw 'User isn\'t registered to this server'
          # When a connection is already registered to a user, close it before storing the new one
          #@sendOne(userId, "close", [])
          connection = @connections.get(userId)
          if connection then connection.close()
          connection = request.accept('json-rpc', request.origin)
          @connections.set(userId, connection)

          #TODO: add scan on om-nomnom, so we can filter conversation
          # in meantime should I store conversation into user ?
          userData = user.publicify()
          userData.capabilityToken = resources.generateTwilioCapabilityToken(user)
          @sendOne(userId, "init", [user.get('conversations'), userData])

          connection.on 'message', (message) =>
            if message.type != 'utf8' then throw "Unsuported data format"
            debug '[' + userId + '] received:', message.utf8Data
            data = JSONRPC.handleRequest(message.utf8Data, UserService, {
              user: user
              twilioClient: resources.twilio
              #conversationMapper: conversationMapper
              userMapper: userMapper
              url: resources.websocketProtocol + '://' + request.host
              app: @
            })
            if data && data.result
              if data.result instanceof Promise
                data.result.then (ret) =>
                  data.result = ret
                  @respond userId, data
              else
                @respond userId, data

          connection.on 'close', (reasonCode, description) =>
            debug '[' + userId + '] disconnected'
            #debug 'Peer ' + connection.remoteAddress + ' disconnected.'
            @connections.set(userId, null)

        .catch (err) =>
          debug 'err', err
          @sendOne(userId, 'error', err)
          if connection then connection.close()
          else request.reject()

    return new App()
