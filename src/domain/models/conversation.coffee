define (require) ->
  Joi = require 'joi'
  _   = require 'lodash'
  AModel = require('om-nomnom').AModel
  Message = require 'models/message'


  class Conversation extends AModel

    @history_size: 200

    @schema: {
      #id: Joi.string() # <user.Id>-<intelocutor.id>
      id: Joi.string().required().regex(/^\+(?:[0-9] ?){6,14}[0-9]$/)
      name: Joi.string().allow("", null)
      note: Joi.string().allow("", null)
      unread: Joi.number().default(0)
      messages: Joi.string().default('[]') # Message[] stringified
    }

    constructor: (attrs) ->
      super(attrs, Conversation.schema)

    statify: () ->
      data = {}
      data.id = @get('id')
      #data.game = games.toJSON().indexOf(@get('game'))
      #data.connection = Boolean(@get('connection'))
      return data

    set: (key, value) ->
      #if key != 'connection' then console.log 'set', key, value
      super(key, value)


    addMessage: (messageData) ->
      message = new Message(messageData)
      messages = JSON.parse(@get('messages') || "[]")
      messages.unshift(message)
      if messages.length > Conversation.history_size then messages.length = Conversation.history_size
      @set('messages', JSON.stringify(messages))
      @set('unread', @get('unread') + 1)

    @createId: (phoneNumber1, phoneNumber2) ->
      #return phoneNumber1 + '-' + phoneNumber2
      return phoneNumber2
