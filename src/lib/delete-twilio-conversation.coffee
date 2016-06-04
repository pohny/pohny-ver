define (require) ->
  Promise = require 'bluebird'
  return (twilioClient, userNumber, contactNumber) ->
    counter = 0

    deleteMessage = (data) ->
      promises = []
      for message in data.messages
        #console.log(message.body)
        p = twilioClient.messages(message.sid).delete()
        .then () ->
          counter++
        .catch (err) ->
          console.log err
        promises.push p
      return Promise.all(promises)

    promises2 = []
    promises2.push twilioClient.messages.list({ to: userNumber, from: contactNumber }).then(deleteMessage)
    if userNumber != contactNumber
      promises2.push twilioClient.messages.list({ to: contactNumber, from: userNumber }).then(deleteMessage)

    Promise.all(promises2)
    .then () ->
      console.log counter + ' message(s) deleted'
