#!/usr/bin/env coffee

# http://nodejs.org/api/child_process.html#child_process_child_process_spawn_command_args_options
child_process = require 'child_process'

# https://github.com/caolan/async/
async = require 'async'

# process options: can't use optimist because it handles arguments that
# look like options as options.

boolopt = {}
argv = {}
process.argv.shift()
process.argv.shift()
while process.argv.length
  a = process.argv[0]
  if a == '--'
    process.argv.shift()
    break
  if a == '-'
    # Probably an argument, not an option.
    break
  if a[0] == '-'
    a = a[1..]
    if boolopt[a]
      argv[a] = true
    else
      process.argv.shift()
      v = process.argv.shift()
      if !isNaN(Number(v))
        v = Number v
      argv[a] = v
  else
    break
argv._ = process.argv.slice()

n = Infinity
if +argv.n
  n = 0|argv.n
utility = 'echo'
if argv._.length >= 1
  utility = argv._[0]
utility_args = argv._[1..]

arg_list = []
arg1 = (arg, cb) ->
  # Unquote the arg.
  arg = arg.replace /'[^']*'|"[^"]*"|\\(?:.|\n)|[^ \n\\'"]/g, (x) ->
    if /^['"]/.test x
      return x[1..-2]
    if x[0] == '\\'
      return x[1]
    return x
  arg_list.push arg
  if arg_list.length >= n
    return invoke cb
  else
    return setTimeout cb, 0
invoke = (cb) ->
  if arg_list.length == 0
    return setTimeout cb, 0
  l = [ 'ignore', 1, 2]
  child = child_process.spawn utility, utility_args.concat(arg_list), stdio: l
  arg_list = []
  child.on 'error', (err) ->
    cb()
  child.on 'exit', (code, signal) ->
    if code == 255
      console.warn "Utility #{utility} exited with code #{code}"
      process.exit 55
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
  re = /[ \n]*((?:'[^']*'|"[^"]*"|\\(?:.|\n)|[^ \n\\'"])+)[ \n]+/gm
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
