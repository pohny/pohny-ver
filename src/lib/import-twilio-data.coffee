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
        conversation.id = k
        conversations[k] = (new Conversation(conversation)).toJSON()
        #promises2.push dbDriver.create 'conversations', conversation
        #console.log('conversation:', conversation)

      ###
      for contactNumber in Object.keys(contactNumbers)
        #promises2.push dbDriver.create 'contacts', { name: "n/a", id: contactNumber, note: "" }
        contacts[contactNumber] =  { name: "", id: contactNumber, note: "" }
      ###

      dbDriver.update 'users', user.get('id'), { conversations: conversations }

      return promises2

  exports.debugImport = (twilioClient, user, dbDriver) ->
    conversationList = [
      { id: "+15005550000", name: "Jon Snow", unread: 3, messages: '[{"me":false,"body":"ghost, fetch me me blade.","at":1465013451},{"me":true,"body":"me me blade ?","at":1465012191},{"me":false,"body":"me got !","at":1465012337}]' },
      { id: "+15005550001", name: "Gregor Clegane", unread: 4, messages: '[{"me":false,"body":"Clegane !","at":1465013051},{"me":true,"body":"Hodor !","at":1464012438},{"me":false,"body":"Clegane ?","at":1464012447},{"me":true,"body":"Ho de dor ...","at":1464012481}]'  },
      { id: "+15005550002", name: "Ramsay Bolton", unread: 1, messages: '[{"me":false,"body":"barbecue tonight ?","at":1465015451}]' },
      { id: "+15005550003", name: "Daenerys Targaryen", unread: 1, messages: '[{"me":false,"body":"Have you seen my dragon ?","at":1463002682}]' },
      { id: "+15005550004", name: "Arya Stark", unread: 0, messages: '[{"me":true,"body":"The girl will never learn","at":1465011682},{"me":false,"body":"A girl has no name","at":1465011382}]' },
      { id: "+15005550005", name: "Sansa Stark", unread: 0, messages: '[{"me":true,"body":"sonial","at":1433011682}]' },
      { id: "+15005550006", name: "Tyrion", unread: 0, messages: '[{"me":false,"body":"I\'m not a high elve ! I hate elves.","at":1404912682}]' }
    ]

    conversations = {}
    for conversation in conversationList
      conversations[conversation.id] = (new Conversation(conversation)).toJSON()
    dbDriver.update 'users', user.get('id'), { conversations: conversations }

  return exports
