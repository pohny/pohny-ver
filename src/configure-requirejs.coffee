requirejs = require("requirejs")
rootDir = __dirname

requirejs.onError = (err) ->
  console.log('Require type:', err.requireType)
  if err.requireType == 'timeout'
    console.log('  Modules: ' + err.requireModules)
  console.log err.stack

requirejs.config({

  nodeRequire: require,

  paths:
    root:        rootDir
    etc:         rootDir + "/etc"
    services:    rootDir + "/domain/services"
    constants:   rootDir + "/domain/constants"
    models:      rootDir + "/domain/models"
    controllers: rootDir + "/controllers"
    lib:         rootDir + "/lib"
})

module.exports = requirejs
