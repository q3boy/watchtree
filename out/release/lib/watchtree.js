// Generated by CoffeeScript 1.3.3
var WatchTree, events, fs, os,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

events = require("events");

fs = require("fs");

os = require('options-stream');

WatchTree = (function(_super) {

  __extends(WatchTree, _super);

  function WatchTree() {
    var options, path, paths, _i, _len;
    paths = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.files = {};
    this.events = {};
    options = paths.pop();
    if (typeof options === 'string') {
      paths.push(options);
      options = {};
    }
    this.stopped = false;
    this.options = os({
      emitDelay: 50,
      filter: /\.(js|coffee|css|styl|stylus|md|yaml|jade|json|jpg|jpeg|png|gif|swf|ico|ini|html|htm|xml|txt)$/
    }, options);
    for (_i = 0, _len = paths.length; _i < _len; _i++) {
      path = paths[_i];
      this.watch(path);
    }
  }

  WatchTree.prototype.watch = function(file, emit) {
    var _this = this;
    if (this.files[file]) {
      return;
    }
    return fs.stat(file, function(err, stat) {
      if (err) {
        _this.emit('error', err);
        return;
      }
      if (stat.isFile()) {
        if (!_this.options.filter.test(file)) {
          return;
        }
        _this.files[file] = fs.watch(file, function(events) {
          return _this.onEvent(events, file);
        });
        if (emit) {
          _this.emitDelay('created', file);
        }
      } else if (stat.isDirectory()) {
        _this.files[file] = fs.watch(file, function(events) {
          return _this.onEvent(events, file);
        });
        fs.readdir(file, function(err, files) {
          var f, _i, _len, _results;
          if (err) {
            _this.emit('error', err);
            return;
          }
          _results = [];
          for (_i = 0, _len = files.length; _i < _len; _i++) {
            f = files[_i];
            _results.push(_this.watch(file + '/' + f, emit));
          }
          return _results;
        });
        if (emit) {
          _this.emitDelay('mkdir', file);
        }
      }
    });
  };

  WatchTree.prototype.onEvent = function(events, file) {
    var evt,
      _this = this;
    if (this.stopped) {
      return;
    }
    evt = null;
    return fs.exists(file, function(exists) {
      if (!exists) {
        if (_this.files[file]) {
          _this.files[file].close();
        }
        delete _this.files[file];
        _this.emitDelay('removed', file);
        return;
      }
      return fs.stat(file, function(err, stat) {
        var isDir, isFile;
        if (err) {
          _this.emit('error', err);
          return;
        }
        isDir = stat.isDirectory();
        isFile = stat.isFile();
        if (isDir) {
          return fs.readdir(file, function(err, files) {
            var f, _i, _len, _results;
            if (err) {
              _this.emit('error', err);
              return;
            }
            _results = [];
            for (_i = 0, _len = files.length; _i < _len; _i++) {
              f = files[_i];
              _results.push(_this.watch(file + '/' + f, true));
            }
            return _results;
          });
        } else if (isFile && events === 'change') {
          return _this.emitDelay('changed', file);
        }
      });
    });
  };

  WatchTree.prototype.emitDelay = function(evt, file) {
    var name,
      _this = this;
    name = evt + '|' + file;
    if (this.events[name]) {
      clearTimeout(this.events[name]);
    }
    return this.events[name] = setTimeout(function() {
      return _this.emitReal(evt, file);
    }, this.options.emitDelay);
  };

  WatchTree.prototype.emitReal = function(evt, file) {
    var name;
    name = evt + '|' + file;
    delete this.events[name];
    this.emit(evt, file);
    return this.emit('all', evt, file);
  };

  WatchTree.prototype.stop = function() {
    var file, watch, _ref;
    _ref = this.files;
    for (file in _ref) {
      watch = _ref[file];
      watch.close();
    }
    this.files = {};
  };

  return WatchTree;

})(events.EventEmitter);

module.exports = function() {
  var args;
  args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return (function(func, args, ctor) {
    ctor.prototype = func.prototype;
    var child = new ctor, result = func.apply(child, args), t = typeof result;
    return t == "object" || t == "function" ? result || child : child;
  })(WatchTree, args, function(){});
};