define (require, exports, module) ->
  return (resources) ->
    debug = require('debug')('twilio-app')
    rp    = require 'request-promise'
    Joi   = require 'joi'
    express = require 'express'
    logger  = require 'morgan'
    Twilio  = require 'twilio'
    bodyParser = require 'body-parser'
    DateHelper = require 'lib/date-helper'
    userMapper = resources.userMapper
    MessageService = require 'services/message-service'


    app = express()
    env = app.get 'env'

    # 1. logger comes first to be able to log everything
    app.use logger(if env != 'prod' then 'dev' else 'short')

    # 2. Classic express configuration
    app.use bodyParser.urlencoded({ extended: true})

    #app.use (req, res, next) ->
    #  TODO: check header content-type, and whitelist only this one
    #  res.setHeader('content-type', 'text/xml')
    #  if req.headers['content-type'] != 'text/xml' then res.sendStatus(406) #resources.respond(406)

    #app.use (req, res, next) ->
    # TODO: whitelist only twilio ip

    # 3. utils method to unify responses and error handling
    respond = (res, code, obj) ->
      res.header("Content-Type", "text/xml")
      resources.respond(res, code, obj)


    getRouteErrorHandler = (res) ->
      return (err) ->
        if err instanceof Error
          debug('error', err.stack)
          respond(res, 500, err)
        else
          respond(res, 400, err)


    messageSchema =
      From:       Joi.string().required()
      To:         Joi.string().required()
      Body:       Joi.string().required()
      MessageSid: Joi.string().required()
      AccountSid: Joi.string().required().valid(resources.twilioConfig.account_sid)


    app.post '/message', (req, res) ->
      # No need for validation as twilio inputs should be consistant ?
      #Joi.attempt(req.body, messageSchema)
      params = req.body
      if Number(params.NumSegments) > 1 then console.log("There is a case for NumSegments !")

      userMapper.get(params.To)
      .then (user) ->
        if !user then throw "User doesn't exist"
        resources.twilio.messages(params.MessageSid).get()
        .then (data) ->
          createdAt = new Date(data.date_created)
          message = { id: data.sid, me: false, body: data.body, at: DateHelper.getTimestampInSec(createdAt) }
          #console.log resources.dataSource.users
          return message

        # Sometime getting message detail trigger a 404, in that case we just generate the timestamp of the message ourselves
        .catch (err) ->
          return { id: params.MessageSid, me: false, body: params.Body, at: DateHelper.getTimestampInSec() }
        .then (message) ->
          MessageService.save(userMapper, user, message, params.From)
          .then () ->
            rp.post {
              uri: 'http://localhost:' + resources.pohnyPort + '/message'
              body: { from: params.From, to: user.get('id'), msg: message }
              json: true
            }
            .then () ->
              debug 'message transmitted to pohny'
              respond res, 200, '<?xml version="1.0" encoding="UTF-8"?><Response></Response>'
      .catch getRouteErrorHandler(res)

    app.post '/called', (req, res) ->
      params = req.body
      userMapper.get(params.To)
      .then (user) ->
        twiml = new Twilio.TwimlResponse()
        twiml.dial () ->
          @client(user.getTwilioClientId())
        respond res, 200, twiml.toString()

    app.post '/call', (req, res) ->
      params = req.body
      #console.log params.From.replace('client:', '+')
      userMapper.get(params.From.replace('client:', '+'))
      .then (user) ->
        twiml = new Twilio.TwimlResponse()
        #twiml.dial () -> @client(req.body.Called)
        twiml.dial {'callerId': user.get('id')}, () -> this.number(params.PhoneNumber)
        respond res, 200, twiml.toString()

    return app
