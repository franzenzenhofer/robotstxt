main = @
EventEmitter = require('events').EventEmitter
parseUri = require './lib/parseuri.js'
_ =  require "underscore"
_.mixin require 'underscore.string'

#GateKeeper
class GateKeeper
  isAllowed: (url) ->
    false
  isDisallowed: (url) ->
    false
  whatsUp: (url) ->
    r = @groups['*'].rules.map (e) ->
      e(url)
    
  groups: {}

#GateKeeperMaker is an EventEmitter
class GateKeeperMaker extends EventEmitter
  txt = ''
  txtA = []
  
  rm = @
  constructor: (@url, @user_agent="a coffee GateKeeper") ->
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
    myGateKeeper = undefined
    currUserAgentGroup = false
    evaluate = (line) =>
      line = _.trim line
      unless _(line).startsWith('#')
        unless line == ''
          kvA = line.split ":"

          
          #only work with valid key value pairs
          if kvA.length<2
            return false
          
          kvA = kvA.map (i) ->
            console.log i
            _(i).trim()
            
          kvA[0]=kvA[0].toLowerCase()
          console.log kvA
          #uppercase all keys
          if kvA[0] == 'user-agent'
            #if this is the first group section, create a new gatekeeper
            if not myGateKeeper
              myGateKeeper = new GateKeeper()
            currUserAgentGroup=myGateKeeper.groups[kvA[1].toLowerCase()] = 
              rules: []
          
          else if kvA[0] == 'sitemap'
              #because we used : to split the line, and there is an : in http://
              kvA.shift()
              url = kvA.join ':'
              
          else
            regExStr = kvA[1];
            if regExStr[0] != '/'
              regExStr='/'+regExStr
            regExStr = regExStr.replace /\//g,'\\/'
            #console.log regExStr[regExStr.length-1]
            
            regExStr = regExStr.replace /\*/g,'.*'
            if regExStr[regExStr.length-1] != '$'
              if regExStr[regExStr.length-1] != '*'
                regExStr=regExStr+'.*'
            rx = new RegExp regExStr
            #console.log rx
            #if kvA[0] == 'disallow'
            if currUserAgentGroup
              currUserAgentGroup.rules.push (url) ->
                if url
                  #console.log 'URL: '+url
                  #console.log kvA[0]+' ->' + kvA[1] + '(' + regExStr + ')'
                  url_match = url.match rx
                  if url_match
                    return r =
                      url: url
                      priority: kvA[1].length
                      type: 'disallow'
                      rule: kvA[1]
                      regexstr: regExStr
                      regex: rx
                      match: url_match
                  else
                    false
                else
                  console.log kvA[0]+' ->' + kvA[1] + '(' + regExStr + ')'
                  false
          
          
          
      else
        console.log "----------"
        console.log line
    
    evaluate line for line in lineA
    if(myGateKeeper)
      console.log "emit event ready"
      @emit "ready", myGateKeeper
    else
      console.log "an error happend"
      @emit "error", myGateKeeper
    console.dir(myGateKeeper)
    #f() for f in myGateKeeper.groups['*'].rules
  
  
/*after the GateKeepers.txt is parsed, he throws a ready event*/
/*offers a method called ask which tests the given string*/
/*returns json */
/*create a GateKeeper*/
# /*create = (GateKeeperstxturl, user-agent) ->
#  new GateKeeper*/
#   

r = new GateKeeperMaker('http://tupalo.com/robots.txt', "hiho").on('ready', (r) ->
  console.log r.whatsUp('/fr/s/washere/lazy_load_pics')
  console.log r.whatsUp('/fr/s/dsfjksdhfjlsdlhfgljsdkg/lazy_load_pics')

);
`setTimeout(function(){ console.log('test')}, 2000);`

#modules.exports = createGateKeeperMaker
