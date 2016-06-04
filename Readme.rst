=========
pohny-ver
=========

I'm traveling and I wanted cheap phone solution that could adapt internationally.
I spent a week to look for decent web phone that would fit those criteria ... I try a few which ended up as a huge waste of time.
Best I found was skype which is buggy, expensive and is owned by microsoft.
Googling around, I found twilio, and spent 3 week-ends (and some evenings) producing pohny-ver and pohny-web.
It's pretty funny when you realise that looking for a decent webphone that manage texting and calling is as long a coding it yourself.


Description
===========

Two servers:

  - twilio-server: on to handle incoming connection from twilio service, receive /message, /call and get /called. http only.
    It's possible and recommanded to use https with a signed certificate. (Self signed certicate don't work with twilio :( )

  - pohny-server: handle pohny clients like pohny-web and pohny-cli, mostly uses websocket, but also use a bit of http for authentication and to communicate with twilio-server.

Requirements
============

- **nodejs**

- **coffeescript** ("npm install -g coffee-script")

- **mocha**  ("npm install -g mocha")

Installation
=============

.. code-block:: bash

  # clone repository and open project folder

  # Install project dependancies (server-side)
  npm install

  # Compile coffee sources
  npm run build

  # Copy env template to desired environment and fill up variables with your credentials
  cp etc/env.sh.dist etc/dev.sh

  # Source your env (will be used by your server AND your tests)
  source ./etc/dev.sh

  # start your project
  npm start

  # run tests
  npm test


Folder architecture
===================

**public**  = public ressources, static content accessible from outside
*(/path/to/project/public/path/to/something is my.website.com/path/to/something) and contains public resources like the index.php but also the css, js and the images.*

**src**     = coffeescript sources

**build**   = compiled js sources

**bin**     = executable scripts

**etc**     = configurations

**test**    = Unit tests, api tests, ...


Current features:
=================

- Contacts: CRUD, list, search, call, and start a sms chat

- Conversations: list sorted by date, delete

- Chat:

  > send and receive sms with a single contact,

  > sms history displayed in a ichat style UI,

  > shortcut to call contact you're chatting with


- Voice:

  > From anywhere in the app receive a call, then via a popup accept or reject it

  > active call are displayed in a stick bar

  > dial a number from keyboard (E.164 Number), when line is on pressing [0-9#*] will send the key


Possible improvements, TODO List:
=================================


Critical
~~~~~~~~

- Rewew voice token somehow and check websocket timeout for idle connections

*Twilio token for voice features are valid 1 hour only. (Although it's a lot less critical if you use twilio failover to redirect call to voicemail)*


Medium
~~~~~~

- Voice: add history of call(received, sent and missed)

- Voice: add mute

- Voice: add a timer to see how long the chat is.

- improve design for buttons


Minor
~~~~~
- Chat: mark message as unsent or sent. This is mostly in rare case where internet would be not stable, or in a case where pohny server or twilio servers will face technical issue.

- Conversation list: add message when no conversation (no data available or something)

- persist database somehow if you're using LocalMapper
(Switching to redis is an easy option, but for that repo I want to keep as few depandancy as possible)

- Cleanup few remaining style attribute in index.html; optimize nyfault.css
