define (require) ->

  return (dataSource, app) ->
    lines = []
    lines.push "===[USERS_LENGTH: " + Object.keys(dataSource['users']).length + ']===>'
    lines.push ''
    for k1, user of dataSource['users']
      connection = user.connection
      user.connection = Boolean(user.connection)
      userData = JSON.parse JSON.stringify(user)
      user.connection = connection
      #userData = (new User(user)).statify()
      lines.push '  - user:' + k1
      lines.push '  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
      userData.connection = Boolean(app.connections.get(userData.id))
      conversations = userData.conversations
      userData.conversations = '[Object]'
      lines.push '  ' + JSON.stringify(userData)
      lines.push '  '
      lines.push "  ===[CONVERSTIONS_LENGTH: " + Object.keys(conversations).length + ']==>'
      lines.push ''
      for k2, conversationData of conversations
        lines.push '    - conversation:' + k2
        lines.push '    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
        lines.push '    ' + JSON.stringify(conversationData)
        lines.push ''
      return lines.join("\n")

  (dataSource) ->
    lines = []
    for collectionName, collection of dataSource
      lines.push collectionName + ": " + Object.keys(dataSource[collectionName]).length
      lines.push '=================================='
      for k, obj of dataSource[collectionName]
        lines.push JSON.stringify(obj)
        lines.push ''
      lines.push ''
      lines.push ''
    return lines.join("\n")
