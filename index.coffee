main = @
EventEmitter = require('events').EventEmitter
parseUri = require './lib/parseuri.js'
_ =  require "underscore"
_.mixin require 'underscore.string'

#Robot
#Robot is an EventEmitter
class RobotMaker extends EventEmitter
  txt = ''
  txtA = []
  rm = @
  constructor: (@url, @user_agent) ->
    if @url
      @uri = parseUri(@url)
    else
      throw new error "no url given"
    if @uri
      @crawl() 
  
  
  crawl: (protocol=@uri.protocol, host=@uri.host, port=@uri.port, path=@uri.path,  user_agent=@user_agent, encoding='utf8') ->
    handler = require protocol
    
    options =
      host: host
      port: if !port and port != "" then port else
        if protocol == "https" then 443 else 80
      path: path
      method: 'GET'
      
    req = handler.request options, (res) => 
      res.setEncoding(encoding)
      
      res.on "data", (chunk) =>
        txtA.push chunk
      
      res.on "end", =>
        txt=txtA.join ''
        console.log txt
        @emit "crawled", txt
        @parse txt
      null
    #todo: set the headers
    #allow more than one header
    req.end()
    null
      
  parse: (txt=txt) =>
    console.log txt
    lineA = txt.split "\n"
    evaluate = (line) ->
      line = _.trim line
      unless _(line).startsWith('#')
        unless line == ''
          kvA = line.split " "
          console.log kvA
          #uppercase all keys
      else
        console.log "----------"
        console.log line
    
    evaluate line for line in lineA
    
  
  
/*after the robots.txt is parsed, he throws a ready event*/
/*offers a method called ask which tests the given string*/
/*returns json */
/*create a robot*/
# /*create = (robotstxturl, user-agent) ->
#  new Robot*/
#  

r = new RobotMaker('http://tupalo.com/robots.txt', "hiho");


