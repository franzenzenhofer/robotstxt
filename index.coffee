EventEmitter = require('events').EventEmitter
parseUri = require './lib/parseuri.js'
_ =  require "underscore"
_.mixin require 'underscore.string'

#helper functions

#a special escape function 
#special as is does not escape * 
RegExp.specialEscape = (str) ->
  specials = new RegExp("[.+?|()\\[\\]{}\\\\]", "g")
  str.replace(specials, "\\$&")

#GateKeeper
#GateKeeper gets returned afte a robots.txt is parsed
class GateKeeper
  constructor: (user_agent) ->
    @setUserAgent(user_agent)
    
  #asks the gatekeeper if a given url is allowed
  #returnes true if it is allowed
  #holds a hidden _allowed value that makes this method reuseable for isDisallowed
  isAllowed: (url, _allowed = true) ->
    a = @whatsUp(url)
    r = true
    prio = 0
    check = (matchO) ->
      if matchO
        if matchO.type is 'disallow'
          if matchO.priority > prio
            r = false
          else if matchO.priority is prio and (r is true or r is undefined)
            r = undefined
        else if matchO.type is 'allow'
          if matchO.priority > prio
            r = true
          else if matchO.priority is prio and (r is false or r is undefined)
            r = undefined
    
    #loop over the rules
    check matchO for matchO in a
    
    if _allowed
      r
    else
      !r
  
  #returnes true if an url is disallowed for crawling 
  isDisallowed: (url) ->
    @isAllowed(url, false)
  
  #determines the group to use and iterates over all rules
  whatsUp: (url) ->
    group = @getGroup()
    r = @groups[group].rules.map (e) ->
      e(url)
  
  why: (url) ->
    a = @whatsUp(url)
    ra = []
    conflict = false
    test = (matchO) ->
      if matchO
        if not ra[0]
          ra.push matchO
        else if matchO.priority > ra[0].priority
          ra.unshift matchO
          conflict = false
        else if matchO.priority < ra[0].priority
          ra.push matchO
          conflict = false
        else if matchO.priority is ra[0].priority
          if matchO.type is r[0].type
            ra.push matchO
          else
            conflict = true
            ra.unshift matchO
    
    test matchO for matchO in a
    r = 
      rules: ra
      allowed: @isAllowed(url)
      disallowed: @isDisallowed(url)
      group: @getGroup()
      user_agent: @user_agent
      conflict: conflict
      
    
  
  setUserAgent: (user_agent) ->
    @user_agent = user_agent.toLowerCase()
  
  #determines which User-Agent group to use
  #default is *
  #most specific (longes) rule wins
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

#RobotsTxt is an EventEmitter
class RobotsTxt extends EventEmitter
  txt = ''
  txtA = []
  
  rm = @
  constructor: (@url, @user_agent="a coffee GateKeeper") ->
    if @url
      @uri = parseUri(@url)
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
            if currUserAgentGroup
              currUserAgentGroup.rules.push (url) ->
                if url
                  url_match = url.match rx
                  if url_match
                    return r =
                      url: url
                      line: line
                      priority: kvA[1].length
                      type: kvA[0]
                      rule: kvA[1]
                      regexstr: regExStr
                      regex: rx
                      match: url_match
                  else
                    false
                else
                  false
      else
        #comments line get parse here
    
    evaluate line for line in lineA
    if(myGateKeeper)
      @emit "ready", myGateKeeper
    else
      @emit "error", myGateKeeper

createRobotsTxt = (url, user_agent = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)') ->
  new RobotsTxt(url, user_agent)


module.exports = createRobotsTxt
