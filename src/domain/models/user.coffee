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
      #connection: Joi.object().allow(null)
      #name: Joi.string().min(3).max(100),
      #ip: Joi.string().min(7).max(50)
    }

    constructor: (attrs) ->
      super(attrs, User.schema)

    set: (key, value) ->
      super(key, value)

    getTwilioClientId: () ->
      return @get('id').replace('+', '')

    publicify: () ->
      return {
        id: @get('id')
        name: @get('name')
      }
