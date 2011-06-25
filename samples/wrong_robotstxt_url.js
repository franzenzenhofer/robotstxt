(function() {
  var r, robotsTxt;
  robotsTxt = require('../index.js');
  try {
    r = robotsTxt('http://www.googleiiiiiiiiiiiiii.com/riobobots.txt', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.iamnnotreallyagooglebot.com/)');
    r.on('crawled', function(txt) {
      return console.log('hiho' + txt);
    });
    r.on('ready', function(gkt) {
      console.log('a ready event happened');
      return console.log(gkt.why('http://www.google.com/setnewsprefs?sfsdfg'));
    });
    r.on('error', function(e) {
      return console.log(e.toString());
    });
  } catch (e_r_r_o_r) {
    console.log("an ERROR happened START");
    console.log(e_r_r_o_r);
    console.log("an ERROR happened END");
  }
}).call(this);
