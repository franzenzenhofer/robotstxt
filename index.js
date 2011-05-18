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
    var rm, txt, txtA;
    __extends(RobotMaker, EventEmitter);
    txt = '';
    txtA = [];
    rm = RobotMaker;
    function RobotMaker(url, user_agent) {
      this.url = url;
      this.user_agent = user_agent;
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
          console.log(txt);
          this.emit("crawled", txt);
          return this.parse(txt);
        }, this));
        return null;
      }, this));
      req.end();
      return null;
    };
    RobotMaker.prototype.parse = function(txt) {
      var evaluate, line, lineA, _i, _len, _results;
      if (txt == null) {
        txt = txt;
      }
      console.log(txt);
      lineA = txt.split("\n");
      evaluate = function(line) {
        var kvA;
        line = _.trim(line);
        if (!(_(line).startsWith('#') && !line === '')) {
          kvA = line.split(" ");
          return console.log(kvA);
        } else {
          console.log("----------");
          return console.log(line);
        }
      };
      _results = [];
      for (_i = 0, _len = lineA.length; _i < _len; _i++) {
        line = lineA[_i];
        _results.push(evaluate(line));
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
}).call(this);
