#print
events = require "events"
fs = require "fs"
os = require 'options-stream'

class WatchTree extends events.EventEmitter

  constructor: (paths...) ->
    @files = {}
    @events = {}

    options = paths.pop()
    if typeof options is 'string'
      paths.push options
      options = {}

    @stopped = false
    @options = os {
      emitDelay:50,
      filter: /\.(js|coffee|css|styl|stylus|md|yaml|jade|json|jpg|jpeg|png|gif|swf|ico|ini|html|htm|xml|txt)$/}
    , options

    for path in paths
      @watch path


  watch : (file, emit) ->

    return if @files[file]
    fs.stat file, (err, stat)=>
      if err
        @emit 'error', err
        return
      if stat.isFile()
        return if not @options.filter.test file
        @files[file] = fs.watch file, (events)=> @onEvent events, file
        @emitDelay 'created', file if emit
      else if stat.isDirectory()
        @files[file] = fs.watch file, (events)=> @onEvent events, file
        fs.readdir file, (err, files) =>
          if err
            @emit 'error', err
            return
          for f in files
            @watch file + '/' + f, emit
        @emitDelay 'mkdir', file if emit
      return

  onEvent : (events, file) ->
    return if @stopped
    evt = null
    fs.exists file, (exists) =>
      if not exists
        @files[file].close() if @files[file]
        delete @files[file]
        @emitDelay 'removed', file
        return

      fs.stat file, (err, stat)=>
        if err
          @emit 'error', err
          return

        isDir = stat.isDirectory()
        isFile = stat.isFile()

        if isDir
          fs.readdir file, (err, files) =>
            if err
              @emit 'error', err
              return
            for f in files
              @watch file + '/' + f, true
        else if isFile and events is 'change'
          @emitDelay 'changed', file

  emitDelay: (evt, file) ->
    name = evt + '|' + file
    clearTimeout @events[name] if @events[name]
    @events[name] = setTimeout =>
      @emitReal evt, file
    , @options.emitDelay

  emitReal: (evt, file) ->
    name = evt + '|' + file
    delete @events[name]
    @emit evt, file
    @emit 'all', evt, file

  stop: ->
    for file, watch of @files
      # console.log watch
      watch.close()
    @files = {}
    return

module.exports = (args...)->
  new WatchTree args...
