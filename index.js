(function() {
  var EventEmitter, GateKeeper, GateKeeperMaker, main, parseUri, r, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  main = this;
  EventEmitter = require('events').EventEmitter;
  parseUri = require('./lib/parseuri.js');
  _ = require("underscore");
  _.mixin(require('underscore.string'));
  RegExp.specialEscape = function(str) {
    var specials;
    specials = new RegExp("[.+?|()\\[\\]{}\\\\]", "g");
    return str.replace(specials, "\\$&");
  };
  GateKeeper = (function() {
    function GateKeeper(user_agent) {
      this.user_agent = user_agent;
      console.log("my user agent");
      console.log(this.user_agent);
    }
    GateKeeper.prototype.isAllowed = function(url, user_agent) {
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      return false;
    };
    GateKeeper.prototype.isDisallowed = function(url, user_agent) {
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      return false;
    };
    GateKeeper.prototype.whatsUp = function(url, user_agent) {
      var group, r;
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      group = this.selectGroup(user_agent);
      return r = this.groups[group].rules.map(function(e) {
        return e(url);
      });
    };
    GateKeeper.prototype.selectGroup = function(user_agent) {
      var k, key, keymatch, rkey, _i, _len, _ref;
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      k = '*';
      _ref = this.groups;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        rkey = key.replace(/\*/g, '.*');
        keymatch = user_agent.match(new RegExp(rkey));
        if (keymatch) {
          if (key.length > k.length) {
            k = key;
          }
        }
      }
      return k;
    };
    GateKeeper.prototype.groups = {};
    return GateKeeper;
  })();
  GateKeeperMaker = (function() {
    var rm, txt, txtA;
    __extends(GateKeeperMaker, EventEmitter);
    txt = '';
    txtA = [];
    rm = GateKeeperMaker;
    function GateKeeperMaker(url, user_agent) {
      this.url = url;
      this.user_agent = user_agent != null ? user_agent : "a coffee GateKeeper";
      this.parse = __bind(this.parse, this);
      if (this.url) {
        this.uri = parseUri(this.url);
      } else {
        throw new error("no url given");
      }
      if (this.uri) {
        this.crawl();
      }
    }
    GateKeeperMaker.prototype.crawl = function(protocol, host, port, path, user_agent, encoding) {
      var handler, options, req;
      if (protocol == null) {
        protocol = this.uri.protocol;
      }
      if (host == null) {
        host = this.uri.host;
      }
      if (port == null) {
        port = this.uri.port;
      }
      if (path == null) {
        path = this.uri.path;
      }
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      if (encoding == null) {
        encoding = 'utf8';
      }
      handler = require(protocol);
      this.user_agent = user_agent;
      options = {
        host: host,
        port: !port && port !== "" ? port : protocol === "https" ? 443 : 80,
        path: path,
        method: 'GET'
      };
      req = handler.request(options, __bind(function(res) {
        res.setEncoding(encoding);
        res.on("data", __bind(function(chunk) {
          return txtA.push(chunk);
        }, this));
        res.on("end", __bind(function() {
          txt = txtA.join('');
          console.log("crawled end");
          this.emit("crawled", txt);
          return this.parse(txt);
        }, this));
        return null;
      }, this));
      req.setHeader("User-Agent", user_agent);
      req.end();
      return null;
    };
    GateKeeperMaker.prototype.parse = function(txt) {
      var currUserAgentGroup, evaluate, line, lineA, myGateKeeper, _i, _len;
      if (txt == null) {
        txt = txt;
      }
      console.log("parse start");
      lineA = txt.split("\n");
      myGateKeeper = void 0;
      currUserAgentGroup = false;
      evaluate = __bind(function(line) {
        var kvA, regExStr, rx, url;
        line = _.trim(line);
        if (!_(line).startsWith('#')) {
          if (line !== '') {
            kvA = line.split(":");
            if (kvA.length < 2) {
              return false;
            }
            kvA = kvA.map(function(i) {
              console.log(i);
              return _(i).trim();
            });
            kvA[0] = kvA[0].toLowerCase();
            console.log(kvA);
            if (kvA[0] === 'user-agent') {
              if (!myGateKeeper) {
                myGateKeeper = new GateKeeper(this.user_agent);
              }
              return currUserAgentGroup = myGateKeeper.groups[kvA[1].toLowerCase()] = {
                rules: []
              };
            } else if (kvA[0] === 'sitemap') {
              kvA.shift();
              return url = kvA.join(':');
            } else {
              regExStr = kvA[1];
              if (regExStr[0] !== '/') {
                regExStr = '/' + regExStr;
              }
              regExStr = RegExp.specialEscape(regExStr);
              console.log('------------------');
              console.log(regExStr);
              regExStr = regExStr.replace(/\*/g, '.*');
              if (regExStr[regExStr.length - 1] !== '$') {
                if (regExStr[regExStr.length - 1] !== '*') {
                  regExStr = regExStr + '.*';
                }
              }
              rx = new RegExp(regExStr);
              if (currUserAgentGroup) {
                return currUserAgentGroup.rules.push(function(url) {
                  var r, url_match;
                  if (url) {
                    url_match = url.match(rx);
                    if (url_match) {
                      return r = {
                        url: url,
                        priority: kvA[1].length,
                        type: 'disallow',
                        rule: kvA[1],
                        regexstr: regExStr,
                        regex: rx,
                        match: url_match
                      };
                    } else {
                      return false;
                    }
                  } else {
                    console.log(kvA[0] + ' ->' + kvA[1] + '(' + regExStr + ')');
                    return false;
                  }
                });
              }
            }
          }
        } else {
          console.log("----------");
          return console.log(line);
        }
      }, this);
      for (_i = 0, _len = lineA.length; _i < _len; _i++) {
        line = lineA[_i];
        evaluate(line);
      }
      if (myGateKeeper) {
        console.log("emit event ready");
        this.emit("ready", myGateKeeper);
      } else {
        console.log("an error happend");
        this.emit("error", myGateKeeper);
      }
      return console.dir(myGateKeeper);
    };
    return GateKeeperMaker;
  })();
  /*after the GateKeepers.txt is parsed, he throws a ready event*/;
  /*offers a method called ask which tests the given string*/;
  /*returns json */;
  /*create a GateKeeper*/;
  r = new GateKeeperMaker('http://www.google.com/robots.txt', "hiho").on('ready', function(r) {
    console.log(r.whatsUp('/fr/s/washere/lazy_load_pics'));
    return console.log(r.whatsUp('/musics'));
  });
  setTimeout(function(){ console.log('test')}, 2000);;
}).call(this);
