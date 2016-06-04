define (require) ->
  Joi = require 'joi'
  _   = require 'lodash'
  AModel = require('om-nomnom').AModel


  class Message extends AModel

    @schema: {
      id: Joi.string().required() # <user.Id>-<intelocutor.id>
      #body: Joi.string().max(160).min(1)
      body: Joi.string().required().min(1)
      me: Joi.boolean().required() # Message[] stringified
      at: Joi.number().required()
    }

    constructor: (attrs) ->
      super(attrs, Message.schema)
