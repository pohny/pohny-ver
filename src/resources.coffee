define (require) ->
  Promise     = require 'bluebird'
  DateHelper  = require 'lib/date-helper'
  env    = process.env.NODE_ENV || 'prod'
  http   = require 'http'
  jwt    = require 'jwt-simple'
  debug  = require('debug')('resource')
  Twilio = require 'twilio'
  om     = require 'om-nomnom'
  User   = require 'models/user'
  Conversation  = require 'models/conversation'
  crypto = require 'crypto'
  setupUsers = require 'lib/setup-users'



  resources = {}

  resources.respond = respond = (res, code, obj) ->
    if env == "prod"
      obj = {code: code, msg: http.STATUS_CODES[code] }

    debug 'http ->', code, obj
    #res.setHeader('content-type', 'content-type')
    res.status(code).send(obj)


  resources.getRouteErrorHandler = (res) ->
    return (err) ->
      if err instanceof Error
        debug('error', err.stack)
        respond(res, 500, err)
      else
        respond(res, 400, err)

  resources.getSecret = () ->
    return process.env.TOKEN_SECRET

  resources.authJWT = (token, secret) ->
    data = jwt.decode(token, secret)
    if DateHelper.getTimestampInSec() > data.expire_at then throw "Expired access token"
    return data.id

  resources.authMiddleware = (req) ->
    #params = req.resourceURL.query
    #for k of params then params[k] = decodeURIComponent(params[k])
    token = decodeURIComponent(req.resourceURL.query['token'])
    debug 'Auth with token:', token

    # Disable auth when on dev
    userId = resources.authJWT(token, resources.getSecret())
    debug 'userId:', userId
    if !userId then throw 'Invalid Token'

    return userId
    #req.userId = userId
    #return req

  twilioConfig = {
    account_sid:  process.env.TWILIO_ACCOUNT_SID
    token:        process.env.TWILIO_AUTH_TOKEN
  }
  resources.twilioConfig = twilioConfig
  resources.twilio   = Promise.promisifyAll Twilio(twilioConfig.account_sid, twilioConfig.token)

  resources.generateTwilioCapabilityToken = (user) ->
    capability = Twilio.Capability(twilioConfig.account_sid, twilioConfig.token)
    capability.allowClientIncoming(user.getTwilioClientId())
    console.log user.getTwilioClientId(), 'connected'
    capability.allowClientOutgoing(user.get("twilio_app_sid"))
    return capability.generate()

  #deleteTwilioConversation = require 'lib/delete-twilio-conversation'
  #phoneNumber =  process.env.TEST_TWILIO_NUMBER
  #deleteTwilioConversation(resources.twilio, phoneNumber, phoneNumber)

  #resources.dataSource = { users: {}, conversations: {}, contacts: {}}
  #resources.conversationMapper = new resources.Mapper(Conversation)
  Conversation.history_size = process.env.MESSAGE_HISTORY_SIZE || 200

  resources.getSalt = () ->
    return crypto.randomBytes(32).toString('base64')

  resources.hash = (secret, salt) ->
    return crypto.pbkdf2Sync(secret, salt, 99997, 32, 'sha512').toString('base64')

  resources.websocketProtocol = process.env.POHNY_WEBSOCKET_PROTOCOL || 'ws'
  pohnyPort   = process.env.POHNY_PORT
  pohnyDomain = process.env.POHNY_DOMAIN || 'localhost'
  pohnyHttpProtocol   = process.env.POHNY_SSL || 'http'
  resources.pohnyUrl  = pohnyHttpProtocol + '://' + pohnyDomain + ':' + pohnyPort
  resources.internalTwilioWhitelistedIp = process.env.TWILIO_INTERNAL_IP || '::ffff:127.0.0.1'
  resources.twilioVoiceFailover   = process.env.TWILIO_VOICE_FAILOVER
  resources.twilioMessageFailover = process.env.TWILIO_MESSAGE_FAILOVER

  initDb = () ->
    #return new Promise (resolve, reject) ->
    resources.dataSource = { users: {}}
    resources.Mapper = om.LocalMapper(resources.dataSource)
    resources.userMapper = new resources.Mapper(User)
    users = JSON.parse process.env.POHNY_USERS
    return setupUsers(resources, users, false)

  initMongo = (mongoURI) ->
    MongoDB = require 'mongodb'
    MongoClient = Promise.promisifyAll(MongoDB).MongoClient
    MongoClient.connect(mongoURI)
    .then (mongo) ->
      resources.mongo = mongo
      resources.Mapper = om.MongoMapper(mongo)
      resources.userMapper = new resources.Mapper(User)

  ###
  initRedis = (redisURI) ->
    Redis = require 'ioredis'
    redisConfig = {
      lazyConnect: false,
      enableOfflineQueue: false
    }
    resources.redis = redis = new Redis(redisURI, redisConfig)
    resources.Mapper = om.RedisMapper(redis)
    resources.userMapper = new resources.Mapper(User)

    redis.on 'error', (e) ->
      console.log e.toString()
      if e && e.code ==  'ECONNREFUSED' then resources.maintenance = true
    return new Promise (resolve, reject) ->
      redis.once 'ready', () ->
        resolve()
        redis.on 'ready', () -> resources.maintenance = false

  ###

  #======================================================================================================
  resources.init = (cb) ->

    promise = null
    promise = switch
      when process.env.MONGO_URI then initMongo(process.env.MONGO_URI)
      #when process.env.REDIS_URI then initRedis(process.env.REDIS_URI)
      else initLocal()

    promise
    .then () ->
      if cb then cb()

  resources.destruct = () ->
    switch
      when process.env.MONGO_URI then resources.mongo.close()
      #when process.env.REDIS_URI then resources.redis.disconnect()


  return resources
