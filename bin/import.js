var requirejs = require("../build/configure-requirejs"),
    resources = requirejs('root/resources'),
    DateHelper = requirejs('lib/date-helper'),
    Promise = requirejs('bluebird')
    setupUsers = requirejs('lib/setup-users');

resources.init( function() {
  var users = JSON.parse(process.env.POHNY_USERS)
  var importEnabled = true
  setupUsers(resources, users, importEnabled)
  .then(function() {
    resources.destruct();
    console.log("the end");
  });
});

