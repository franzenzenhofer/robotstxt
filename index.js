(function() {
  var EventEmitter, GateKeeper, RobotsTxt, createRobotsTxt, parseUri, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
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
      this.setUserAgent(user_agent);
    }
    GateKeeper.prototype.isAllowed = function(url, _allowed) {
      var a, check, matchO, prio, r, _i, _len;
      if (_allowed == null) {
        _allowed = true;
      }
      a = this.whatsUp(url);
      r = true;
      prio = 0;
      check = function(matchO) {
        if (matchO) {
          if (matchO.type === 'disallow') {
            if (matchO.priority > prio) {
              return r = false;
            }
          } else if (matchO.type === 'allow') {
            if (matchO.priority >= prio) {
              return r = true;
            }
          }
        }
      };
      for (_i = 0, _len = a.length; _i < _len; _i++) {
        matchO = a[_i];
        check(matchO);
      }
      if (_allowed) {
        return r;
      } else {
        return !r;
      }
    };
    GateKeeper.prototype.isDisallowed = function(url) {
      return this.isAllowed(url, false);
    };
    GateKeeper.prototype.whatsUp = function(url) {
      var group, r;
      group = this.getGroup();
      return r = this.groups[group].rules.map(function(e) {
        return e(url);
      });
    };
    GateKeeper.prototype.why = function(url) {
      var a, conflict, matchO, r, ra, test, _i, _len;
      a = this.whatsUp(url);
      ra = [];
      conflict = false;
      test = function(matchO) {
        if (matchO) {
          if (!ra[0]) {
            return ra.push(matchO);
          } else if (matchO.priority > ra[0].priority) {
            ra.unshift(matchO);
            return conflict = false;
          } else if (matchO.priority < ra[0].priority) {
            ra.push(matchO);
            return conflict = false;
          } else if (matchO.priority === ra[0].priority) {
            if (matchO.type === r[0].type) {
              return ra.push(matchO);
            } else {
              conflict = true;
              return ra.unshift(matchO);
            }
          }
        }
      };
      for (_i = 0, _len = a.length; _i < _len; _i++) {
        matchO = a[_i];
        test(matchO);
      }
      return r = {
        url: url,
        rules: ra,
        allowed: this.isAllowed(url),
        disallowed: this.isDisallowed(url),
        group: this.getGroup(),
        user_agent: this.user_agent,
        conflict: conflict
      };
    };
    GateKeeper.prototype.setUserAgent = function(user_agent) {
      return this.user_agent = user_agent.toLowerCase();
    };
    GateKeeper.prototype.getGroup = function(user_agent) {
      var k, key, keymatch, rkey, value, _ref;
      if (user_agent == null) {
        user_agent = this.user_agent;
      }
      user_agent = user_agent.toLowerCase();
      if (this.user_agent_group[user_agent]) {
        return this.user_agent_group[user_agent];
      } else {
        k = '*';
        _ref = this.groups;
        for (key in _ref) {
          value = _ref[key];
          rkey = key.replace(/\*/g, '.*');
          keymatch = user_agent.match(new RegExp(rkey));
          if (keymatch) {
            if (key.length > k.length) {
              k = key;
            }
          }
        }
        this.user_agent_group[user_agent] = k;
        return k;
      }
    };
    GateKeeper.prototype.groups = {};
    GateKeeper.prototype.user_agent = null;
    GateKeeper.prototype.user_agent_group = {
      '*': '*'
    };
    return GateKeeper;
  })();
  RobotsTxt = (function() {
    var rm, txt, txtA;
    __extends(RobotsTxt, EventEmitter);
    txt = '';
    txtA = [];
    rm = RobotsTxt;
    function RobotsTxt(url, user_agent) {
      this.url = url;
      this.user_agent = user_agent != null ? user_agent : "a coffee GateKeeper";
      this.parse = __bind(this.parse, this);
      if (this.url) {
        this.uri = parseUri(this.url);
        this.crawl();
      }
    }
    RobotsTxt.prototype.crawl = function(protocol, host, port, path, user_agent, encoding) {
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
      txt = '';
      txtA = [];
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
          this.emit("crawled", txt);
          return this.parse(txt);
        }, this));
        return null;
      }, this));
      req.setHeader("User-Agent", user_agent);
      req.end();
      return null;
    };
    RobotsTxt.prototype.parse = function(txt) {
      var currUserAgentGroup, evaluate, line, lineA, line_counter, myGateKeeper, _i, _len;
      if (txt == null) {
        txt = txt;
      }
      lineA = txt.split("\n");
      myGateKeeper = void 0;
      currUserAgentGroup = false;
      evaluate = __bind(function(line, nr) {
        var kvA, regExStr, rx, url;
        line = _.trim(line);
        if (!_(line).startsWith('#')) {
          if (line !== '') {
            kvA = line.split(":");
            if (kvA.length < 2) {
              return false;
            }
            kvA = kvA.map(function(i) {
              return _(i).trim();
            });
            kvA[0] = kvA[0].toLowerCase();
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
                        line: line,
                        linenumber: nr,
                        priority: kvA[1].length,
                        type: kvA[0],
                        rule: kvA[1],
                        regexstr: regExStr,
                        regex: rx,
                        match: url_match
                      };
                    } else {
                      return false;
                    }
                  } else {
                    return false;
                  }
                });
              }
            }
          }
        } else {
          ;
        }
      }, this);
      line_counter = 0;
      for (_i = 0, _len = lineA.length; _i < _len; _i++) {
        line = lineA[_i];
        evaluate(line, ++line_counter);
      }
      if (myGateKeeper) {
        return this.emit("ready", myGateKeeper);
      } else {
        return this.emit("error", myGateKeeper);
      }
    };
    return RobotsTxt;
  })();
  createRobotsTxt = function(url, user_agent) {
    if (user_agent == null) {
      user_agent = 'Mozilla/5.0 (compatible; Open-Source-Coffee-Script-Robots-Txt-Checker/2.1; +http://example.com/bot.html)';
    }
    return new RobotsTxt(url, user_agent);
  };
  module.exports = createRobotsTxt;
}).call(this);
