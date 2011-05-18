(function() {
  var EventEmitter, RobotMaker, main, parseUri, r;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
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
  RobotMaker = (function() {
    var rm;
    __extends(RobotMaker, EventEmitter);
    rm = RobotMaker;
    rm.txt = '';
    rm.txtA = [];
    function RobotMaker(url, user_agent) {
      this.url = url;
      this.user_agent = user_agent;
      rm.uri = parseUri(this.url);
    }
    RobotMaker.prototype.crawl = function(protocol, host, port, path, user_agent, encoding) {
      var handler, options, req;
      if (protocol == null) {
        protocol = rm.uri.protocol;
      }
      if (host == null) {
        host = rm.uri.host;
      }
      if (port == null) {
        port = rm.uri.port;
      }
      if (path == null) {
        path = rm.uri.path;
      }
      if (user_agent == null) {
        user_agent = rm.user_agent;
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
      return req = handler.request(options, function(res) {
        res.setEncoding(encoding);
        res.on("data", function(chunk) {
          rm.txtA.push(chunk);
          return console.log(chunk);
        });
        return res.on("end", function() {
          console.log("end");
          rm.txt = rm.txtA.join('');
          console.log(rm.txt);
          return rm.emit("crawled", m.txt);
        });
      });
    };
    RobotMaker.prototype.parse = function(txt) {
      if (txt == null) {
        txt = rm.txt;
      }
    };
    return RobotMaker;
  })();
  /*after the robots.txt is parsed, he throws a ready event*/;
  /*offers a method called ask which tests the given string*/;
  /*returns json */;
  /*create a robot*/;
  r = new RobotMaker('http:www.google.com/robots.txt', "hiho");
}).call(this);
