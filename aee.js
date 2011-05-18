(function() {
  var AwesomeEventEmitter, EventEmitter, aee;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  EventEmitter = require('events').EventEmitter;
  AwesomeEventEmitter = (function() {
    __extends(AwesomeEventEmitter, EventEmitter);
    function AwesomeEventEmitter() {
      AwesomeEventEmitter.__super__.constructor.apply(this, arguments);
    }
    return AwesomeEventEmitter;
  })();
  aee = new AwesomeEventEmitter;
  aee.emit("test");
  aee.on("test", function() {
    return console.log("test happened");
  });
}).call(this);
