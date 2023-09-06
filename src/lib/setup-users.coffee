define (require) ->
  fs = require 'fs'
  User = require 'models/user'
  Promise = require 'bluebird'
  return (resources, users, importEnabled) ->
    promises = []
    if users instanceof Array == false
      throw "WARNING: No user created"
      # Note: if you're using another way to insert user, simply set POHNY_USERS to '[]' to disable exeption above

    for userData in users
      password = userData.password
      twilioAppSid = userData.twilio_app_sid
      phoneNumber =  userData.phone
      salt = resources.getSalt()


      user = new User({id: phoneNumber, twilio_app_sid: twilioAppSid, salt: salt, conversations: {} })
      user.set('password', resources.hash(password, salt))

      p = resources.userMapper.get(user.get('id'))
      .then (user2, args...) ->
        if !user2
          console.log "creating user" + user.get("id")
          resources.userMapper.create(user)
          .then () ->
            # NOTE: Only use IMPORT_ENABLED is you're using LocalMapper (see resources.coffee)
            if importEnabled
              TwilioData = require 'lib/import-twilio-data'
              return TwilioData.import(resources.twilio, user, resources.Mapper)
              #TwilioData.debugImport(resources.twilio, user, resources.Mapper)
          .catch (err) ->
            console.log "WARNING: Cannot import user's data"
            console.log err
            console.log "*ignore if you're using testing credentials"
      promises.push p

    return Promise.all promises
