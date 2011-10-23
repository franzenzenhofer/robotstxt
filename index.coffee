#http://code.google.com/web/controlcrawlindex/docs/robots_txt.html
EventEmitter = require('events').EventEmitter
parseUri = require './lib/parseuri.js'
_ =  require "underscore"
_.mixin require 'underscore.string'
#helper functions
##console.log 'HHHHHHHHHHHHHEEEEEEEEEEEEEEELLLLLLLLLLLLOOOOOOOOOOO'
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
            #console.log matchO
            #console.log 'D I S A L L O W'
            prio = matchO.priority
            r = false

          #this undefined is deprecated, as allow always wins
          #else if matchO.priority is prio and (r is true or r is undefined)
            #r = undefined

        else if matchO.type is 'allow'
          if matchO.priority >= prio
            #console.log 'A L L O W S T A R T'
            #console.log matchO
            #console.log 'A L L O W E N D'
            prio = matchO.priority
            r = true
          #this undefined is deprecated, as allow always wins
          #else if matchO.priority is prio and (r is false or r is undefined)
            #r = undefined


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
    url = @cleanUrl(url)
    group = @getGroup()
    r = @groups[group].rules.map (e) ->
      e(url)

  why: (url) ->
    url = @cleanUrl(url)
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
      url: url
      rules: ra
      allowed: @isAllowed(url)
      disallowed: @isDisallowed(url)
      group: @getGroup()
      user_agent: @user_agent
      conflict: conflict

  cleanUrl: (url) ->
    xu = parseUri(url)
    if xu.path and xu.path isnt ''
      if xu.query and xu.query isnt ''
        return xu.path+'?'+xu.query
      else
        if _(url).endsWith('?')
          return xu.path+'?'
        else
          return xu.path



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

  #return the requested Crawl-delay for ...
  #  ... the specified user agent (if specified)
  #  ... the configured user agent (if present)
  #  ... the default user agent
  #if there is no match, undefined is returned.
  getCrawlDelay: (user_agent = @user_agent) ->
    user_agent = user_agent.toLowerCase()
    delay = @groups[user_agent]?.crawl_delay or @groups['*'].crawl_delay
    Number delay if delay?

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
    txt = ''
    txtA = []
    handler = require protocol
    @user_agent = user_agent
    options =
      host: host
      port: if !port and port != "" then port else
        if protocol == "https" then 443 else 80
      path: path
      method: 'GET'

    req = handler.request options, (res) =>
        if 200 <= res.statusCode < 300 # 2xx, Successful
            res.setEncoding(encoding)
            res.on "data", (chunk) =>
              txtA.push chunk
            res.on "end", =>
              txt=txtA.join ''
              @emit "crawled", txt
              @parse txt
            null
        # removed HTTP 3xx redirects, as googlebot does not support it either
        # as the robots.txt protocol is domain dependend
        # and only valid if it's really the /robots.txt file
        # yeah, the robots.txt is a pretty stupid protocol (but good enough)
        #else if 300 <= res.statusCode < 400 # 3xx, redirect
        #    req.end()
        #    @uri = parseUri(res.headers.location)
        #    return @crawl()
        else
            @emit "error", new Error 'invalid status code - is: HTTP '+res.statusCode+' - should: HTTP 200'
    #set the headers
    req.setHeader "User-Agent",user_agent
    #todo: allow more than one header
    req.end()
    null

    req.on('error', (e) =>
        @emit "error", e
      )

  parse: (txt=txt) =>
    ##console.log ('PARSED')
    lineA = txt.split "\n"
    myGateKeeper = undefined
    currUserAgentGroup = false
    groupGroupsA = []

    #dirty function, wordk
    #copyrules = (groupname) ->
    #  myGateKeeper.groups[groupname].rules = currUserAgentGroup.rules;
    #  #console.log 'groupname '+groupname

    evaluate = (line, nr) =>
      line = _.trim line
      unless _(line).startsWith('#')
        unless line == ''
          #kvA = line.split ":"
          # get rid of anythiny behind an #

          doublepoint=line.indexOf(':')
          if _(line).includes('#')
            kvA = [line.substr(0,doublepoint), line.substr(doublepoint+1,line.indexOf('#')-(doublepoint+1))];
          else
            kvA = [line.substr(0,doublepoint), line.substr(doublepoint+1)];
          console.log(kvA);


          #only work with valid key value pairs
          if kvA.length isnt 2
            return false
          #and skipt all blank rules
          #hmmm but an invalid rule might still have grouping impact
          #else if kvA.length is 2 and kvA[1] is ''
          #  return false



          kvA = kvA.map (i) ->
            _(i).trim()


          #lowercase all keys
          kvA[0]=kvA[0].toLowerCase()
          if kvA[0] == 'user-agent'
            #if this is the first group section, create a new gatekeeper
            if not myGateKeeper
              myGateKeeper = new GateKeeper(@user_agent)


            # look if there are group to groups
            if currUserAgentGroup?.rules?.length == 0
              groupGroupsA.push currUserAgentGroup.name
              ##console.log groupGroupsA
            else
              groupGroupsA = []

             #create a new useragent group
            currUserAgentGroup = myGateKeeper.groups[kvA[1].toLowerCase()] =
              name: kvA[1].toLowerCase()
              rules: []

            #if there are groups to group we make a reference to the current rules object
            if groupGroupsA?.length > 0
              ((groupname) -> (myGateKeeper.groups[groupname].rules = currUserAgentGroup.rules)) groupname for groupname in groupGroupsA



          else if kvA[0] == 'sitemap'
              #whatever we do with the sitemap

          else if kvA[0] == 'crawl-delay'
            if currUserAgentGroup
              currUserAgentGroup.crawl_delay = kvA[1]
            #TODO: What do we do if there is no currUserAgentGroup?

          else
            regExStr = kvA[1]+'';
            if regExStr == ''
              # invalid rule, but we clean all groups to group
              groupGroupsA = []
            else
              if regExStr[0] != '/'
                regExStr='/'+regExStr
              regExStr = RegExp.specialEscape regExStr

              regExStr = regExStr.replace /\*/g,'.*'
              if regExStr[regExStr.length-1] != '$'
                if regExStr[regExStr.length-1] != '*'
                  regExStr=regExStr+'.*'

              #The path value is used as a basis to determine whether or not a rule applies to a specific URL on a site. With the exception of wildcards, the path is used to match the beginning of a URL (and any valid URLs that start with the same path).

              regExStr='^'+regExStr
              rx = new RegExp regExStr
              if currUserAgentGroup
                currUserAgentGroup.rules.push (url) ->
                  if url
                    url_match = url.match rx
                    if url_match
                      return r =
                        url: url
                        line: line
                        linenumber: nr
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
    line_counter=0
    evaluate line, ++line_counter for line in lineA
    if myGateKeeper?
      ##console.log 'my freaking gatekeeper'
      ##console.log myGateKeeper
      ##console.log myGateKeeper.groups
      ##console.log 'my freaking gatekeeper end'
      @emit "ready", myGateKeeper
    else
      @emit "error", 'gatekeeper is '+ typeof myGateKeeper

createRobotsTxt = (url, user_agent = 'Mozilla/5.0 (compatible; Open-Source-Coffee-Script-Robots-Txt-Checker/2.1; +http://example.com/bot.html)') ->
  new RobotsTxt(url, user_agent)


module.exports = createRobotsTxt
