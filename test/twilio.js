var should  = require('chai').should(),
    expect  = require('chai').expect,
    fs      = require('fs'),
    jwt     = require('jwt-simple'),
    supertest   = require('supertest'),
    requirejs = require("../build/configure-requirejs"),
    resources = requirejs('root/resources'),
    DateHelper = requirejs('lib/date-helper'),


port = process.env.TEST_PORT || process.env.TWILIO_PORT
var base_http_url = 'http://localhost:' + (Number(port));
var message = JSON.parse(fs.readFileSync('./etc/message.json'))
var called = JSON.parse(fs.readFileSync('./etc/called.json'))

users = JSON.parse(process.env.POHNY_USERS)
phoneNumber = users[0].phone
called.Called = phoneNumber
called.To = phoneNumber
message.From = phoneNumber
message.To = phoneNumber
message.Body +=  ' - ' + new Date()
message.MessageSid +=Date.now()

describe('Testing twilio endpoints on ' + base_http_url, function() {

  var api = supertest(base_http_url);
  this.timeout(1000);

  before(function(done) {
    done();
  })

  it('post messages', function(done) {

    api
    .post('/message')
    .type('form')
    .send(message)
    .expect(200)
    .end( function(err, res) {
      if(err) done(err);
      else {
        //console.log(res.body);
        done();
      }
    });
  });

  it('post call', function(done) {
    api
    .post('/called')
    .type('form')
    .send(called)
    .expect(200)
    .end( function(err, res) {
      if(err) done(err);
      else {
        //console.log(res.body);
        done();
      }
    });
  });

});
