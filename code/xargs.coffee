#!/usr/bin/env coffee

# https://github.com/substack/node-optimist
optimist = require 'optimist'

argv = optimist.boolean('tpx'.split '').argv

# Input buffer.
input = ''
process.stdin.on 'data', (data) ->
  input += data
  re = /[ \n]*((?:'[^']*'|"[^"]*"|\\[.\n]|[^ \n\\'"])+)[ \n]+/gm
  # When loop is finished, remove initial *trim* characters of *input*.
  trim = 0
  while true
    group = re.exec input
    if not group
      break
    process.stdout.write group[1] + '\n'
    trim = re.lastIndex
  if trim
    input = input[trim..]
process.stdin.on 'end', -> process.exit 0

process.stdin.resume()
