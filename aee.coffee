EventEmitter = require('events').EventEmitter
class AwesomeEventEmitter extends EventEmitter
  constructor: (@name) ->
  
  secondtest: () ->
    @emit "secondtest"
  
aee = new AwesomeEventEmitter "jack"

aee.on("test", () ->
  console.log "test happend")
aee.on("secondtest", (t) ->
  console.log "secondtest happend ")
  
aee.emit "test" 
aee.secondtest("2nd")
