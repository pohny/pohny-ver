define (require) ->
  debug = require('debug')('user-service')
  _ = require 'lodash'
  DateHelper = require 'lib/date-helper'
  Conversation  = require 'models/conversation'
  MessageService = require 'services/message-service'

  class UserService

    constructor: () -> throw new Error('static class, cannot be instanciated')

    ###
    #TODO: move below to a twilio service
    @send_message: (targetNumber, msg) ->
      console.log 555, @twilioClient.sendMessage
      @twilioClient.sendMessage({ to: targetNumber, from: @user.get('id'), body: msg })
      .then (data) ->
        message = { id: data.sid, me: true, body: data.body, at: DateHelper.getTimestampInSec(data.date_created) }
        conversationId = Conversation.createId(@user.get('id'), targetNumber)
        #return conversationmapper.get(conversationid)
        return @user.get('conversations')[conversationid]
      .then (conversation) ->
        if conversation == null then conversation = new Conversation({ id: conversationId, unread: 1, messages: [] })
        conversation.addMessage(message)
        #return conversationMapper.update(conversation)
        @user.get('conversations')[conversation.id] = conversation
        @userMapper.update(@user)
      .then () -> return 'ok'


    @mark_conversation_as_read: (targetNumber) ->
      conversationId = Conversation.createId(@user.get('id'), targetNumber)
      @conversationMapper.update(conversationId, { unread: 0 })

    @get_conversation: (targetNumber) ->
      @conversationMapper.get(@user.get('id') + targetNumber)
      .then (conversation) =>
        if conversation == null then throw "conversation doesn't exists"
        #@app.sendOne [@userId, 'create_conversation', conversation]
        #TODO: would make more sense protocol wise if this func would return a jsonrpc response
        return conversation

    @call: (targetNumber) ->
      @twilioClient.call({
        to: targetNumber,
        from: @user.get('id'),
        url: @url + '/called'
      })

    @hangup: (callSid) ->
      twilioClient.calls(callSid).update { status: "completed" }
      .then (call) -> console.log 'call terminated', call.direction
      .catch (err) -> console.log 'error: call failed to terminate', err

    @getToken: () ->
      return resources.generateTwilioCapabilityToken()
    ###

  UserService['conversations.remove'] =  (id, data) ->
    conversations = @user.get('conversations')
    delete conversations[id]
    @user.set('conversations', conversations)
    @userMapper.update(@user)

  UserService['conversations.change'] =  (id, data) ->
    conversations = @user.get('conversations')
    conv = new Conversation(conversations[id])
    conv.set('name', data.name)
    conv.set('note', data.note)
    conversations[id] = conv.toJSON()
    @user.set('conversations', conversations)
    @userMapper.update(@user)

  UserService['conversations.read'] =  (id) ->
    conversations = @user.get('conversations')
    conv = new Conversation(conversations[id])
    conv.set('unread', 0)
    conversations[id] = conv.toJSON()
    @user.set('conversations', conversations)
    @userMapper.update(@user)

  UserService['conversations.add'] =  (id, data) ->
    data.messages = '[]'
    data.unread = 0
    conversations = @user.get('conversations')
    conversations[id] = (new Conversation(data)).toJSON()
    @user.set('conversations', conversations)
    @userMapper.update(@user)

  UserService['messages.add'] =  (id, data) -> MessageService.send(@twilioClient, @userMapper, @user, id, data)
  UserService['messages.reset'] = (id) -> MessageService.reset(@userMapper, @user, id)

  return UserService
