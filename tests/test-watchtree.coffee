#mocha
e = require 'expect.js'
fs = require 'fs'
path = require 'path'
cp = require 'child_process'

isDir = (p) ->
  fs.existsSync(p) and fs.statSync(p).isDirectory()

rmdirp = (p) ->
  # try
  return if not isDir p
  files = fs.readdirSync p
  if not files.length
    try fs.rmdirSync p
  else
    for file in files
      p1 = path.join p, file
      if isDir p1
        rmdirp p1
      else
        try fs.unlinkSync p1
  try fs.rmdirSync p
  return

run = (cmd) ->
  cp.exec cmd, (err) ->
    throw err if err

dir = __dirname + '/test'
clean = (done)->
  try rmdirp dir
  try fs.mkdirSync dir, '0755'

  setTimeout done, 100
  return
describe 'watchtree', ->
  beforeEach clean
  after clean
  watchtree = require '../lib/watchtree'
  describe 'basic events', ->
  it 'start and stop', (done)->
    wt = watchtree dir
    setTimeout ->
      t = new Date
      wt.stop()
      e(new Date().valueOf() - t.valueOf()).to.lessThan 1000
      done()
    , 100


  describe 'dir events', ->
    it '"mkdir" emitted', (done)->
      wt = watchtree dir, interval: 100
      wt.on 'all', (evt, file) ->
        e(evt).to.be 'mkdir'
        e(file).to.be dir + '/dir1'
        wt.stop() || done()
      setTimeout (->fs.mkdirSync dir+'/dir1', '0755'), 100

    it '"removed" emitted', (done)->
      wt = watchtree dir
      wt.on 'mkdir', (file) ->
        e(file).to.be dir + '/dir2'
        e(wt.files).to.have.key dir + '/dir2'
        fs.rmdirSync dir+'/dir2', '0755'
      wt.on 'removed', (file) ->
        e(file).to.be dir + '/dir2'
        e(wt.files).to.not.have.key dir + '/dir2'
        wt.stop() || done()
      setTimeout (->fs.mkdirSync dir+'/dir2', '0755'), 100

  describe 'file events', ->

    it '"created" emitted', (done)->
      wt = watchtree dir
      wt.on 'created', (file) ->
        e(file).to.be dir + '/file1.js'
        wt.stop() || done()
      setTimeout (->fs.writeFileSync dir+'/file1.js', 'somedata'), 100

    it '"removed" emitted', (done)->
      wt = watchtree dir
      wt.on 'created', (file) ->
        e(file).to.be dir + '/file2.js'
        e(wt.files).to.have.key dir + '/file2.js'
        fs.unlinkSync dir+'/file2.js'

      wt.on 'removed', (file) ->
        e(file).to.be dir + '/file2.js'
        e(wt.files).to.not.have.key dir + '/file2.js'
        wt.stop() || done()
      setTimeout (-> fs.writeFileSync dir+'/file2.js', 'somedata'), 100

    it '"changed" emitted', (done)->
      wt = watchtree dir
      wt.on 'created', (file) ->
        e(file).to.be dir + '/file3.js'
        setTimeout (-> fs.appendFileSync dir+'/file3.js', '2'), 100
      wt.on 'changed', (file) ->
        e(file).to.be dir + '/file3.js'
        e(fs.readFileSync(dir + '/file3.js').toString()).to.be '12'
        wt.stop() || done()
      setTimeout (-> fs.writeFileSync dir+'/file3.js', '1'), 100

    it 'exists file changed', (done)->
      fs.mkdirSync dir+'/dir0', '0755'
      fs.writeFileSync dir+'/file0.js', 'some data'
      wt = watchtree dir
      wt.on 'all', (evt, file) ->
        e(evt).to.be 'changed'
        e(file).to.be dir + '/file0.js'
        wt.stop() || done()
      setTimeout ->
        fs.writeFileSync dir+'/file0.js', 'some data1'
      , 100

  describe 'others', ->

    it 'event emit delay', (done)->
      wt = watchtree dir, emitDelay:100
      wt.on 'created', (file) ->
        e(file).to.be dir + '/file6.js'
        setTimeout (-> fs.appendFileSync dir+'/file6.js', '2'), 10
        setTimeout (-> fs.appendFileSync dir+'/file6.js', '3'), 80
        setTimeout (-> fs.appendFileSync dir+'/file6.js', '4'), 160
        setTimeout (-> fs.appendFileSync dir+'/file6.js', '5'), 300
      flag = 0
      wt.on 'changed', (file) ->
        e(file).to.be dir + '/file6.js'
        switch ++flag
          when 1 then e(fs.readFileSync(dir + '/file6.js').toString()).to.be '1234'
          when 2 then e(fs.readFileSync(dir + '/file6.js').toString()).to.be '12345'
      setTimeout ->
        e(flag).to.be 2
        wt.stop()
        done()
      , 1000
      setTimeout (-> fs.writeFileSync dir+'/file6.js', '1'), 100


    it 'deep path watch', (done)->
      this.timeout 2000
      wt = watchtree dir
      flag = 0

      wt.on 'mkdir', (file) ->
        switch ++flag
          when 1 then e(file).to.be dir + '/dir3'
          when 2 then e(file).to.be dir + '/dir3/dir4'
          when 3 then e(file).to.be dir + '/dir3/dir4/dir5'
          when 4 then e(false).to.be false

      wt.on 'created', (file) ->
        switch ++flag
          when 4 then e(file).to.be dir + '/dir3/dir4/dir5/file4.js'
          when 5 then e(file).to.be dir + '/dir3/dir4/dir5/file5.js'
          when 6 then e(false).to.be false

      setTimeout (->
        e(flag).to.be 5
        wt.stop()
        done()
      ), 500
        # setTimeout (-> wt.stop() || done()), 8000

      setTimeout ->
        fs.mkdirSync dir+'/dir3/', '0755'
        fs.mkdirSync dir+'/dir3/dir4/', '0755'
        fs.mkdirSync dir+'/dir3/dir4/dir5', '0755'
        fs.writeFileSync dir+'/dir3/dir4/dir5/file4.js', 'somedata1'
        fs.writeFileSync dir+'/dir3/dir4/dir5/file5.js', 'somedata2'
      , 100
