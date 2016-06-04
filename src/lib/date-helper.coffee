define (require) ->
  _ = require 'lodash'


  class DateHelper

    @DAY_SEC: 60 * 60 * 24
    @WEEK_SEC: DateHelper.DAY_SEC * 7

    @DAY_MSEC: DateHelper.DAY_SEC * 1000
    @WEEK_MSEC: DateHelper.WEEK_SEC * 1000

    @getTimestampInSec: (date) ->
     if date == undefined then date = new Date()
     if _.isDate(date) == false then throw new Error("getTimestampInSec requires a date object")
     return Math.floor( date.getTime() / 1000)

    @nowInSec: @getTimestampInSec

    @getYYYYMMDD: (date) ->
     if date == undefined then date = new Date()
     if _.isDate(date) == false then throw new Error("getYYYYMMDD requires a date object")
     return parseInt(date.toISOString().split('T')[0].replace(/-/g, ''))
