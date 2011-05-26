
#require the robotsTxt module
robotsTxt = require '../index.js'

#create a new parser
#add some callback action
r = robotsTxt('http://www.google.com/robots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)').on('ready', (gk) ->
  console.log gk.isAllowed('http://www.google.com/setnewsprefs?sfsdfg')
  console.log gk.isAllowed('http://www.google.com/gp/richpub/syltguides/create/hudriwudri')
  console.log gk.isDisallowed('/news/directory?pz=1&cf=all&ned=us&hl=en&sort=users&category=4/')
  console.log gk.isDisallowed('/musics')
  console.log gk.getGroup()
  console.log gk.why('/news/directory?pz=1&cf=all&ned=us&hl=en&sort=users&category=4/')
);


r2 = robotsTxt('http://www.google.com/robots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)')