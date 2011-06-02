robots.txt parser for node.js
===

  - robotstxt is written in coffee script
  - robotstxt is currently alpha
  - robotstxt offers an easy way to obey the allow/disallow rules listed in the sites robots.txt


Install:

    npm install robotstxt
    

all examples use coffee script syntax

require:

    robotsTxt = require 'robotstxt'

parse a robots.txt:
    
    #robotsTxt(url, user_agent)
    google_robots_txt = robotsTxt 'http://www.google.com/robots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)'

assign event handler after all that parsing is done

    google_robots_txt.on 'ready', (gate_keeper) -> 
      #returns false
      console.log gate_keeper.isAllowed 'http://www.google.com/setnewsprefs?sfsdfg'
      #returns false
      console.log gate_keeper.isAllowed '/setnewsprefs?sfsdfg'
      #returns true
      console.log gate_keeper.isDisallowed 'http://www.google.com/setnewsprefs?sfsdfg' 
      #returns true
      console.log gate_keeper.isDisallowed '/setnewsprefs?sfsdfg'
    
gate_keeper methods:

    #asks the gate_keeper if it's ok to crawle an url
    isAllowed url
    #asks the gate_keeper if it's not ok to crawle an url
    isDisallowed url
    #answeres the question, why an url is allowed/disallowed
    why url
    #if you want to change the user agent that is used for this question
    setUserAgent user_agent
    #if you want to know which robots.txt group is used with which user_agent
    #per default uses the user agent set with setUserAgent
    getGroup (user_agent)
    
robotsTxt methods
  
    #fetches parses url with user_agent
    #returns an robots_txt event emitter
    robotsTxt(url, user_agent)
    
    #blank robots_txt object
    blank_robots_txt = robotsTxt()
    
    #crawls and parses a robots.txt 
    #throws an 'crawled' event
    blank_robots_txt.crawl: (protocol, host, port, path,  user_agent, encoding)
    
    #parses a txt string line after line
    #throws a 'ready' event
    blank_robots_txt.parse(txt)
    
    
robotsTxt events

    #thrown after the whole robots.txt is crawled
    robotsTxt.on 'crawled' (txt) -> ...
  
    #thrown after all lines of the robots.txt are parsed
    robotsTxt.on 'ready' (gate_keeper)
    

**NOTES**

the default user-agent used is

    #robotsTxt(url, user_agent)
    Mozilla/5.0 (compatible; Open-Source-Coffee-Script-Robots-Txt-Checker/2.1; +http://example.com/bot.html
    
i strongly recommend using your own user agent

i.e.:

    myapp_robots_txt = robotsTxt 'http://www.google.com/robots.txt', 'Mozilla/5.0 (compatible; MyAppBot/2.1; +http://www.example.com/)'
    
    
if you want to simulate another crawler (for testing purposes only, of course) see this list for the correct user agent strings 

  - [List of User Agent Strings] (http://www.useragentstring.com/pages/useragentstring.php)
  - [Googlebot] (http://www.google.com/support/webmasters/bin/answer.py?answer=1061943)
    

ToDo
---
  - ready event should also pass a sitemaps_in_robots_txt object
  - sitemaps_in_robots_txt should offer methods to collect the urls listed in the sitemap

Resources
---
  - [Robots.txt Specifications by Google](http://code.google.com/web/controlcrawlindex/docs/robots_txt.html)
 