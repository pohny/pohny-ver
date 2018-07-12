var should  = require('chai').should(),
    expect  = require('chai').expect,
    jwt     = require('jwt-simple'),
    supertest   = require('supertest'),
    requirejs = require("../build/configure-requirejs"),
    resources = requirejs('root/resources'),
    DateHelper = requirejs('lib/date-helper');


var port = process.env.POHNY_PORT
var phoneNumber = process.env.TEST_TWILIO_NUMBER;
var domain = '127.0.0.1';
var base_http_url = 'http://' + domain + ':' + (Number(port));
describe('Testing auth endpoints on ' + base_http_url, function() {

  var api = supertest(base_http_url);
  this.timeout(1000);

  var users = JSON.parse(process.env.POHNY_USERS);
  var phoneNumber = users[0].phone;
  var password = users[0].password;
  var refreshToken = '';
  var accessToken = '';

  before(function(done) {
    done();
  })

  it('Auth with login / password', function(done) {

    api
    .post('/auth')
    .type('form')
    .send({ phone: phoneNumber, password: password, is_trusted: true})
    .expect(200)
    .end( function(err, res) {
      if(err) done(err);
      else {
        refreshToken = res.body.refresh_token;
        accessToken = res.body.accessToken;
        done();
      }
    });
  });

  it('refresh accessToken', function(done) {
    api
    .post('/refresh')
    .type('form')
    .send({ refresh_token: refreshToken, phone: phoneNumber })
    .expect(200)
    .end( function(err, res) {
      if(err) done(err);
      else {
        done();
      }
    });
  });

});
