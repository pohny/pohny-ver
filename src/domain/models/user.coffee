define (require) ->
  Joi = require 'joi'
  _   = require 'lodash'
  AModel = require('om-nomnom').AModel


  class User extends AModel
    @schema: {
      id: Joi.string().required().regex(/^\+(?:[0-9] ?){6,14}[0-9]$/)
      twilio_app_sid: Joi.string()
      name: Joi.string()
      password: Joi.string()
      #contacts: Joi.array()
      #conversations: Joi.object()
      conversations: Joi.string()
      #connection: Joi.object().allow(null)
      #name: Joi.string().min(3).max(100),
      #ip: Joi.string().min(7).max(50)
    }

    constructor: (attrs) ->
      super(attrs, User.schema)

    set: (key, value) ->
      if key == 'conversations' && _.isString(value) == false then value = JSON.stringify(value)
      super(key, value)

    get: (key) ->
      value = super(key)
      if key == 'conversations' && value != undefined then value = JSON.parse(value)
      return value

    getTwilioClientId: () ->
      return @get('id').replace('+', '')

    publicify: () ->
      return {
        id: @get('id')
        name: @get('name')
      }
