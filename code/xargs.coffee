#!/usr/bin/env coffee

# http://nodejs.org/api/child_process.html#child_process_child_process_spawn_command_args_options
child_process = require 'child_process'

# https://github.com/caolan/async/
async = require 'async'
# https://github.com/substack/node-optimist
optimist = require 'optimist'

argv = optimist.boolean('tpx'.split '').argv

n = Infinity
if +argv.n
  n = 0|argv.n
utility = 'echo'
arg_list = []
arg1 = (arg, cb) ->
  arg_list.push arg
  if arg_list.length >= n
    return invoke cb
  else
    return setTimeout cb, 0
invoke = (cb) ->
  if arg_list.length == 0
    return setTimeout cb, 0
  l = [ 'ignore', 1, 2]
  child = child_process.spawn utility, arg_list, stdio: l
  arg_list = []
  child.on 'error', (err) ->
    cb()
  child.on 'exit', (code, signal) ->
    cb()

# Slightly complicated state handling to deal with case
# when we get the stdin 'end' event while we are in
# a 'data' event.
readingData = false
ended = false

# Input buffer.
input = ''
process.stdin.on 'data', (data) ->
  readingData = true
  input += data
  re = /[ \n]*((?:'[^']*'|"[^"]*"|\\[.\n]|[^ \n\\'"])+)[ \n]+/gm
  args = []
  # When loop is finished, remove initial *trim* characters of *input*.
  trim = 0
  while true
    group = re.exec input
    if not group
      break
    args.push group[1]
    trim = re.lastIndex
  if trim
    input = input[trim..]
  process.stdin.pause()
  async.eachSeries args, arg1, ->
    readingData = false
    process.stdin.resume()
    if ended
      # got stdin 'end' while we were in the async call
      invoke ->
        process.exit 77

process.stdin.on 'end', ->
  if readingData
    ended = true
  else
    invoke ->
      process.exit 88

process.stdin.resume()
nothing = ->
# setInterval nothing, 1e6
