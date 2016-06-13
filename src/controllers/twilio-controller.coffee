define (require) ->
  router = require('express').Router()
  Joi    = require 'joi'
  MessageService = require 'services/message-service'
  Promise = require 'bluebird'

  return (app) ->
    resources = app.get('resources')
    respond = resources.respond
    getRouteErrorHandler = resources.getRouteErrorHandler
    userMapper = resources.userMapper

    message = (req, res) ->
      body = req.body
      userMapper.get(body.to)
      .then (user) ->
        if !user then throw "User doesn't exist"
        MessageService.save(userMapper, user, body.msg, body.from)
        .then () ->
          if app.isConnected(user.get('id')) == false then throw "User is not connected"
          app.sendOne(body.to, 'message', [body.from, body.msg])
          respond(res, 200)
          # TODO: manage access policy in authMiddleware ?
          #ip = req.connection.remoteAddress || req.headers['X-Forwarded-For']
          #if ip != '127.0.0.1' then throw 'message in an internal of pohny'
        .catch getRouteErrorHandler(res)

    called = (req, res) ->
      body = req.body
      userMapper.get(body.to)
      .then (user) ->
        # TODO: add a voiceservice to log incoming call (missed and received ..)
        if !user then throw "User doesn't exist"
        if app.isConnected(user.get('id')) == false then throw "User is not connected"
        respond(res, 200, user.get('id'))
      .catch getRouteErrorHandler(res)

    #TODO: add a middleware to whitelist only query from twilio-server
    whiteListMiddleware = (req, res, next) ->
      ip = req.connection.remoteAddress || req.headers['X-Forwarded-For']
      if ip == resources.internalTwilioWhitelistedIp
        next()
      else
        respond res, 403, 'Access refused, host is not whitelisted'

    router.post '/called',  whiteListMiddleware, called
    router.post '/message', whiteListMiddleware, message

    return router
