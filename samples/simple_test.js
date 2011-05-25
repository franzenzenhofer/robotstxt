(function() {
  var r, robotsTxt;
  robotsTxt = require('../index.js');
  r = robotsTxt('http://www.google.com/robots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)').on('ready', function(gk) {
    console.log(gk.isAllowed('/setnewsprefs?sfsdfg'));
    console.log(gk.isAllowed('/gp/richpub/syltguides/create/hudriwudri'));
    console.log(gk.isDisallowed('/news/directory?pz=1&cf=all&ned=us&hl=en&sort=users&category=4/'));
    console.log(gk.whatsUp('/news/directory?pz=1&cf=all&ned=us&hl=en&sort=users&category=4/'));
    console.log(gk.isDisallowed('/musics'));
    return console.log(gk.getGroup());
  });
}).call(this);
