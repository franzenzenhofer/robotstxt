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
  robot = {}
  rm = @
  constructor: (@url, @user_agent="a coffee robot") ->
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
        #console.log txt
        console.log "crawled end"
        @emit "crawled", txt
        @parse txt
      null
    #set the headers
    req.setHeader "User-Agent",user_agent
    #todo: allow more than one header
    req.end()
    null
      
  parse: (txt=txt) =>
    #console.log txt
    console.log "parse start"
    lineA = txt.split "\n"
    currUserAgent = false
    evaluate = (line) ->
      line = _.trim line
      unless _(line).startsWith('#')
        unless line == ''
          kvA = line.split " "
          #only work with valid key value pairs
          if kvA.length<2
            return false
            
          kvA[0]=kvA[0].toUpperCase()
          console.log kvA
          #uppercase all keys
          if kvA[0] == 'USER-AGENT:'
            currUserAgent=robot[kvA[1]]=
              allow: []
              disallow: []
              #noindex: []
          else if kvA[0] == 'SITEMAP:'
              
          else
            regExStr = kvA[1];
            if regExStr[0] != '/'
              '/'+regExStr
              
            regExStr = regExStr.replace /\*/g,'.*'
            
            if kvA[0] == 'DISALLOW:'
              if currUserAgent
                currUserAgent.disallow.push (url) ->
                  console.log 'DISALLOW ->' + kvA[1] + '(' + regExStr + ')'
            else if kvA[0] == 'ALLOW:'
              if currUserAgent
                currUserAgent.allow.push (url) ->
                  console.log 'ALLOW ->' + kvA[1]
            #else if kvA[0] == 'NOINDEX:'
            # if currUserAgent
            #   currUserAgent.noindex.push (url) ->
            #     console.log 'NOINDEX ->' + kvA[1]
           
          
          
      else
        console.log "----------"
        console.log line
    
    evaluate line for line in lineA
    console.dir(robot)
    f() for f in robot['*'].disallow
  
  
/*after the robots.txt is parsed, he throws a ready event*/
/*offers a method called ask which tests the given string*/
/*returns json */
/*create a robot*/
# /*create = (robotstxturl, user-agent) ->
#  new Robot*/
#  

r = new RobotMaker('http://tupalo.com/robots.txt', "hiho");


