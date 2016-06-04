###
# This script get the last 1000 sent messages and the last 1000 received messages.
# Next, it store and then sort the 2000 messages received,
# trim the conversation.message according to the history_size
# and finally save it in database.
# /!\ It is not recommanded to use this script if you want to import more than 1000 messages.
###
define (require) ->
  DateHelper = require 'lib/date-helper'
  Promise = require 'bluebird'
  Conversation = require 'models/conversation'
  exports = {}
  exports.import = (twilioClient, user, dbDriver) ->
    history_size = process.env.MESSAGE_HISTORY_SIZE || 200
    page_size = 1000

    promises = []
    promises.push(twilioClient.messages.list({ to: user.get('id'), pageSize: page_size }))
    promises.push(twilioClient.messages.list({ from: user.get('id'), pageSize: page_size }))

    Promise.all(promises)
    .then (results) ->
      m2 = null
      conversations = {}
      contactNumbers = {}
      contacts = {}
      isSender = null
      contactNumber = null
      for response in results
        #console.log 'page size', response.page_size
        for m1 in response.messages
          isSender = m1.from == user.get('id')
          contactNumber = if isSender then m1.to else m1.from
          contactNumbers[contactNumber] = null
          conversationId =  Conversation.createId(user.get('id'), contactNumber)
          if conversations[conversationId] == undefined
            conversations[conversationId] = { id: conversationId, messages: [] }

          conversations[conversationId].messages.push({
            id: m1.sid, body: m1.body,
            me: m1.direction == "outbound-api" && isSender,
            at: DateHelper.getTimestampInSec(new Date(m1.date_created))
          })
          #console.log conversations[conversationId].messages.length

      #console.log 'conversationIds:', Object.keys(conversations)
      promises2 = []
      for k, conversation of conversations
        conversation.messages.sort (x, y) -> return y.at - x.at
        if conversation.messages.length > history_size then conversation.messages.length = history_size
        # NOTE: better to display innacurate number of unread than missing message
        conversation.unread = conversation.messages.length
        conversation.messages = JSON.stringify conversation.messages
        conversation.phone = k
        conversation.note = ""
        conversation.name = ""
        conversations[k] = new Conversation(conversation)
        #promises2.push dbDriver.create 'conversations', conversation
        #console.log('conversation:', conversation)

      ###
      for contactNumber in Object.keys(contactNumbers)
        #promises2.push dbDriver.create 'contacts', { name: "n/a", id: contactNumber, note: "" }
        contacts[contactNumber] =  { name: "", phone: contactNumber, note: "" }
      ###

      dbDriver.update 'users', user.get('id'), { conversations: conversations }

      return promises2

  exports.debugImport = (twilioClient, user, dbDriver) ->
    conversations = {
      "+15005550006": { phone: "+15005550006", name: "Valid and available" },
      "+15005550001": { phone: "+15005550001", name: "Invalid" },
      "+15005550000": { phone: "+15005550000", name: "Unavailable" }
    }


    for k, conversation of conversations
      conversation.unread = 0
      conversations[k] = new Conversation(conversation)
    dbDriver.update 'users', user.get('id'), { conversations: conversations }

  return exports
