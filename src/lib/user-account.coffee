define (require) ->
  router = require('express').Router()
  Joi    = require 'joi'
  jwt    = require 'jwt-simple'
  _     = require 'lodash'
  DateHelper = require 'lib/date-helper'
  Promise = require 'bluebird'
  joiOptions = { abortEarly: false }


  return (app) ->

    resources = app.get('resources')
    respond = resources.respond
    getRouteErrorHandler = resources.getRouteErrorHandler
    userMapper = resources.userMapper


    userAccountSchema = {
      #email:    Joi.string().required().email()
      phone:   Joi.string().required()
      password:   Joi.string().required().min(6).max(100)
      is_trusted: Joi.boolean()
    }

    getAccessToken = (user) ->
      secret = resources.getSecret()
      accessToken = jwt.encode({ id: user.get('id'), expire_at: DateHelper.getTimestampInSec() + DateHelper.DAY_SEC }, secret)
      return accessToken

    getRefreshToken = (user) ->
      return jwt.encode( user.get('id'), user.get('salt'))

    getTokens = (user, isTrustedDevice) ->
      result = { access_token: getAccessToken(user) }
      if isTrustedDevice then result.refresh_token = getRefreshToken(user)
      return result

    authLimit = 0
    authTimeout = null
    auth = (req, res, next) ->
      body = req.body
      ip = req.connection.remoteAddress || req.headers['X-Forwarded-For']

      Promise.try () ->
        if authLimit > 20 then throw "Auth attempt limit reached"
        result = Joi.validate(body, userAccountSchema, joiOptions)
        if result.error then throw result.error.details
        values = result.value

        return userMapper.get(values.phone)
        .then (user) =>
          # Matching user userect, if valid, update it
          if Boolean(user) == false || resources.hash(values.password, user.get('salt')) != user.get('password')
            authLimit++
            clearTimeout(authTimeout)
            setTimeout (() -> authLimit = 0), 15 * 60 * 1000
            throw "Invalid User-Password Combination"

          isTrusted = values.is_trusted
          data = getTokens(user, isTrusted)
          data.phone = user.get('id')
          respond(res, 200, data)
      .catch (err) ->
        getRouteErrorHandler(res)(err)


    refreshLimit = 0
    refreshTimeout = null
    refresh = (req, res, next) ->
      body = req.body
      ip = req.connection.remoteAddress || req.headers['X-Forwarded-For']

      Promise.try () ->
        if refreshLimit > 10 then throw "Refresh attempt limit reached"
        Joi.attempt(body.refresh_token, Joi.string())
        phone = Joi.attempt(body.phone, userAccountSchema.phone)
        return userMapper.get(phone)
      .then (user) ->
        if user and jwt.decode(body.refresh_token, user.get('salt')) == user.get('id')
          res.json( { access_token: getAccessToken(user) })
        else
          refreshLimit++
          clearTimeout(refreshTimeout)
          setTimeout (() -> refreshLimit = 0), 15 * 60 * 1000
          throw 'Provided refresh token is invalid'
      .catch getRouteErrorHandler(res)



    message = (req, res) ->
      body = req.body
      Promise.try () ->
        app.sendOne(body.to, 'message', [body.from, body.msg])
        respond(res, 200)
        # TODO: manage access policy in authMiddleware ?
        #ip = req.connection.remoteAddress || req.headers['X-Forwarded-For']
        #if ip != '127.0.0.1' then throw 'message in an internal of pohny'
      .catch getRouteErrorHandler(res)

    router.post '/message',   message
    router.post '/auth',      auth
    router.post '/refresh',   refresh
    return router
