robotsTxt = require '../index.js'

try 
  r = robotsTxt('http://www.googleiiiiiiiiiiiiii.com/riobobots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)')
  
  r.on('crawled', (txt) -> console.log 'hiho' + txt )
  
  r.on('ready', (gkt) ->
    console.log 'a ready event happened'
    console.log gkt.why('http://www.google.com/setnewsprefs?sfsdfg')
  )
  
  r.on('error', (e) ->
    console.log e.toString() 
  )

catch e_r_r_o_r
  console.log "an ERROR happened START"
  console.log e_r_r_o_r
  console.log "an ERROR happened END"