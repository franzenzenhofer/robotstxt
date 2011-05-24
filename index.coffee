main = @
EventEmitter = require('events').EventEmitter
parseUri = require './lib/parseuri.js'
_ =  require "underscore"
_.mixin require 'underscore.string'

#helper

RegExp.specialEscape = (str) ->
  #special as is does not escape * 
  specials = new RegExp("[.+?|()\\[\\]{}\\\\]", "g")
  str.replace(specials, "\\$&")

#GateKeeper
class GateKeeper
  constructor: (user_agent) ->
    @setUserAgent(user_agent)
    
  isAllowed: (url) ->
    a = @whatsUp(url)
    r = true
    prio = 0
    collector = {}
    check = (matchO, allowed = true) ->
      if allowed is false
        look_for = 'allow'
      else
        look_for = 'disallow'
      
      if matchO
        if matchO.type is 'allow'
          if matchO.priority > prio
            r = false
          if matchO.priority is prio and (r is true or r is undefined)
            r = undefined
         
    check matchO for matchO in a
    r
  
  isDisallowed: (url) ->
    @isAllowed(url, false)
  
  whatsUp: (url) ->
    group = @getGroup()
    r = @groups[group].rules.map (e) ->
      e(url)
      
    
  
  setUserAgent: (user_agent) ->
    @user_agent = user_agent.toLowerCase()
  
  getGroup: (user_agent = @user_agent) ->
    user_agent = user_agent.toLowerCase()
    if @user_agent_group[user_agent]
      return @user_agent_group[user_agent]
    else
      k = '*'
      for key, value of @groups
        rkey = key.replace /\*/g,'.*'
        keymatch = user_agent.match(new RegExp rkey)
        if keymatch
          if key.length > k.length
            k = key
      @user_agent_group[user_agent] = k
      k
    
  groups: {}
  user_agent: null
  user_agent_group: {'*':'*'}

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
    @user_agent = user_agent
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
        @emit "crawled", txt
        @parse txt
      null
    #set the headers
    req.setHeader "User-Agent",user_agent
    #todo: allow more than one header
    req.end()
    null
      
  parse: (txt=txt) =>
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
            _(i).trim()
            
          kvA[0]=kvA[0].toLowerCase()
          #uppercase all keys
          if kvA[0] == 'user-agent'
            #if this is the first group section, create a new gatekeeper
            if not myGateKeeper
              myGateKeeper = new GateKeeper(@user_agent)
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
            regExStr = RegExp.specialEscape regExStr
            
            regExStr = regExStr.replace /\*/g,'.*'
            if regExStr[regExStr.length-1] != '$'
              if regExStr[regExStr.length-1] != '*'
                regExStr=regExStr+'.*'
            rx = new RegExp regExStr
            #if kvA[0] == 'disallow'
            if currUserAgentGroup
              currUserAgentGroup.rules.push (url) ->
                if url
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
                  false
          
          
          
      else
        console.log line
    
    evaluate line for line in lineA
    if(myGateKeeper)
      @emit "ready", myGateKeeper
    else
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

r = new GateKeeperMaker('http://www.123people.at/robots.txt', "Googlebot Was Here").on('ready', (r) ->
  console.log r.whatsUp('/fr/s/washere/lazy_load_pics')
  console.log r.whatsUp('/musics')
  console.log r.isAllowed('/fr/s/washere/lazy_load_pics')
  console.log r.isAllowed('/musics')
  console.log r.isDisallowed('/fr/s/washere/lazy_load_pics')
  console.log r.isDisallowed('/musics')

);
`setTimeout(function(){ console.log('test')}, 2000);`

#modules.exports = createGateKeeperMaker
