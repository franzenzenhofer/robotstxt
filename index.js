(function() {
  var EventEmitter, RobotMaker, main, parseUri, r, _;
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
  RobotMaker = (function() {
    var rm, robot, txt, txtA;
    __extends(RobotMaker, EventEmitter);
    txt = '';
    txtA = [];
    robot = {};
    rm = RobotMaker;
    function RobotMaker(url, user_agent) {
      this.url = url;
      this.user_agent = user_agent != null ? user_agent : "a coffee robot";
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
    RobotMaker.prototype.crawl = function(protocol, host, port, path, user_agent, encoding) {
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
    RobotMaker.prototype.parse = function(txt) {
      var currUserAgent, evaluate, f, line, lineA, _i, _j, _len, _len2, _ref, _results;
      if (txt == null) {
        txt = txt;
      }
      console.log("parse start");
      lineA = txt.split("\n");
      currUserAgent = false;
      evaluate = function(line) {
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
              return currUserAgent = robot[kvA[1].toLowerCase()] = {
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
              regExStr = regExStr.replace(/\//g, '\\/');
              regExStr = regExStr.replace(/\*/g, '.*');
              if (regExStr[regExStr.length - 1] !== '$') {
                if (regExStr[regExStr.length - 1] !== '*') {
                  regExStr = regExStr + '.*';
                }
              }
              rx = new RegExp(regExStr);
              if (currUserAgent) {
                return currUserAgent.rules.push(function(url) {
                  var r, rx_match;
                  if (url != null) {
                    console.log('URL: ' + url);
                    console.log(kvA[0] + ' ->' + kvA[1] + '(' + regExStr + ')');
                    rx_match = rx.match;
                    if (rx_match(url)) {
                      return r = {
                        priority: kvA[1].lenght,
                        type: 'disallow',
                        rule: kvA[1],
                        regexstr: regExStr,
                        regex: rx,
                        match: rx_match
                      };
                    } else {
                      console.log(kvA[0] + ' ->' + kvA[1] + '(' + regExStr + ')');
                      return false;
                    }
                  }
                });
              }
            }
          }
        } else {
          console.log("----------");
          return console.log(line);
        }
      };
      for (_i = 0, _len = lineA.length; _i < _len; _i++) {
        line = lineA[_i];
        evaluate(line);
      }
      console.dir(robot);
      _ref = robot['*'].rules;
      _results = [];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        f = _ref[_j];
        _results.push(f());
      }
      return _results;
    };
    return RobotMaker;
  })();
  /*after the robots.txt is parsed, he throws a ready event*/;
  /*offers a method called ask which tests the given string*/;
  /*returns json */;
  /*create a robot*/;
  r = new RobotMaker('http://tupalo.com/robots.txt', "hiho");
  setTimeout(function(){ console.log('test')}, 2000);;
}).call(this);
