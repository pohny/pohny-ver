define (require) ->
  debug = require('debug')('user-service')
  _ = require 'lodash'
  DateHelper = require 'lib/date-helper'
  Conversation  = require 'models/conversation'

  class MessageService

    constructor: () -> throw new Error('static class, cannot be instanciated')

    @save = (userMapper, user, message, id) =>
      conversations = user.get('conversations') || {}
      convData = conversations[id]
      if convData == undefined then convData = { id: id, unread: 0, messages: '[]' }
      conv = new Conversation(convData)
      conv.addMessage(message)
      conversations[id] = conv.toJSON()
      user.set('conversations', conversations)
      return userMapper.update(user)

    @send = (twilioClient, userMapper, user, id, data) ->
      if data.me
        # send message
        twilioClient.sendMessage({ to: id, from: user.get('id'), body: data.body })
        .then (data2) ->
          message = { id: data2.sid, me: true, body: data2.body, at: DateHelper.getTimestampInSec(new Date(data2.date_created)) }
          console.log 'messages.add success'
          return MessageService.save(userMapper, user, message, id)
        .catch (err) ->
          console.log 'messages.add failed', err.stack, data
          data.sent = false
          try return MessageService.save(userMapper, user, data, id)
          catch err then console.log err
        .then () -> return 'ok'

    @reset = (userMapper, user, id) ->
      user.get('conversations')[id].messages = '[]'
      return userMapper.update(user)
