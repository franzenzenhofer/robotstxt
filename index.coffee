main = @
EventEmitter = require('events').EventEmitter
parseUri = require('./lib/parseuri.js')

#Robot
#Robot is an EventEmitter
class RobotMaker extends EventEmitter
  txt = ''
  txtA = []
  constructor: (@url, @user_agent) ->
    if @url
      rm.uri = parseUri(@url)
    else
      console.log "no url given"
  
  
  crawl: (protocol=rm.uri.protocol, host=rm.uri.host, port=rm.uri.port, path=rm.uri.path,  user_agent=rm.user_agent, encoding='utf8') ->
    handler = require(protocol)
    
    options =
      host: host
      port: if !port and port != "" then port else
        if protocol == "https" then 443 else 80
      path: path
      method: 'GET'
      
    req = handler.request options, (res) ->
      res.setEncoding(encoding)
      
      res.on "data", (chunk) ->
        rm.txtA.push chunk
        console.log chunk
      
      res.on "end", ->
        console.log "end"
        rm.txt=rm.txtA.join ''
        console.log rm.txt
        rm.emit "crawled", m.txt
      
    
  
  parse: (txt=rm.txt) ->
    
  
  
/*after the robots.txt is parsed, he throws a ready event*/
/*offers a method called ask which tests the given string*/
/*returns json */
/*create a robot*/
# /*create = (robotstxturl, user-agent) ->
#  new Robot*/
#  

r = new RobotMaker('http:www.google.com/robots.txt', "hiho");


