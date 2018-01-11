#
# Copyright 2014-2017 T2T Inc. All rights reserved.
#
require! <[fs path async mkdirp lodash]>
{Transform, ADD} = require \./helpers/common

const NAME = \daily-backup



class Processor
  (@backup-dir, @output-dir, @depth, @verbose) ->
    p1 = path.basename backup-dir
    p2 = path.basename output-dir
    @output-dir = "#{output-dir}/#{p1}" unless p1 is p2
    xs = p1.split '-'
    [server, name] = xs
    @name = name
    @name = \unknown unless @name?
    @.reset-outputs!
    return

  reset-outputs: ->
    @outputs = []

  print-output-line: (line) ->
    {outputs} = self = @
    return outputs.push line

  run: (done) ->
    {backup-dir, output-dir, depth, verbose} = self = @
    f = (file, cb) ->
      fullpath-input = "#{backup-dir}/#{file}"
      fullpath-output = "#{output-dir}/#{file}.txt"
      # console.log "processing #{fullpath-input}"
      t = new Transform {}
      (process-err) <- t.process fullpath-input
      return cb process-err if process-err?
      (traverse-err, text) <- t.traverse-tree self.depth
      return cb traverse-err if traverse-err?
      console.log "successfully traverse #{file} ..., output: #{text.length} bytes." if verbose
      (write-err) <- fs.writeFile fullpath-output, text
      return cb write-err if write-err?
      return cb null, t
    (mkdirp-err) <- mkdirp output-dir
    return done mkdirp-err if mkdirp-err?
    (readdir-err, dirs) <- fs.readdir backup-dir
    return done readdir-err if readdir-err?
    self.files = [ x for x in dirs when x.endsWith \.json ]
    # console.log self.files.join '\n'
    (process-err, transforms) <- async.mapSeries self.files, f
    return done process-err if process-err?
    xs = [ t.get-total-count! for t in transforms ]
    xs = lodash.reduce xs, ADD
    self.transforms = lodash.sortBy transforms, <[count]>
    self.print-output-line "graph LR;"
    for let t, i in transforms
      count = t.get-total-count!
      id = t.get-id!
      self.print-output-line "\tn0(#{self.name}: #{xs}) --> n#{i+1}(#{id}: #{count})"
    text = self.outputs.join '\n'
    index-file = "#{output-dir}/index.txt"
    (write-err) <- fs.writeFile index-file, text
    return done write-err if write-err?
    console.log "successfully write index file: #{index-file}"
    # console.log text
    return done!


module.exports = exports =
  command: NAME
  describe: "analyze the directory of all point count in series of all nodes for entire daily backup"

  builder: (yargs) ->
    yargs
      .alias \b, \backup
      .describe \b, 'the path to the backup directory'
      .alias \d, \depth
      .describe \d, 'the depth of sensor tree for these series to process'
      .default \d, 3
      .alias \o, \output
      .describe \o, 'the path of the output directory for mermaid format files'
      .alias \v, \verbose
      .describe \v, 'output verbose messages'
      .default \v, no
      .alias \t, \top
      .describe \t, 'the top nodes with maximum data points, e.g. top 10'
      .default \t, 10
      .alias 'h', 'help'
      .demand <[b d o v t]>
      .example """
          analyzer #{NAME} --backup ~/Downloads/ifdb001-dhvac-20180105-1h-count --depth 2 --output /tmp

      """
      .epilogue """
          After produing the mermaid text file, you can use following 2 commands to generate graphics:

            mermaid -s -o /tmp /tmp/index.txt && open -a "Google Chrome" /tmp/index.txt.svg
            mermaid -p -o /tmp /tmp/index.txt && open /tmp/aa.txt.png
      """


  handler: (argv) ->
    {backup, depth, output, verbose, top} = argv
    console.log "backup => #{backup}"
    console.log "depth => #{depth}"
    console.log "output => #{output}"
    p = new Processor backup, output, depth, verbose
    (err) <- p.run
    return console.error err if err?
    xs = [ t.get-total-count! for t in p.transforms ]
    ys = [ t.get-total-series! for t in p.transforms ]
    xs-count = xs.length
    ys-count = ys.length
    xs = lodash.reduce xs, ADD
    ys = lodash.reduce ys, ADD
    console.log "total #{xs} points in #{ys} series for #{xs-count} nodes."
    console.log "=> #{(xs/xs-count).toFixed 0} points/node, #{(xs/ys).toFixed 0} points/series"
    console.log "top #{top} nodes:"
    for let i from 1 to top
      t = p.transforms[p.transforms.length - i]
      console.log "#{t.get-id!} => #{t.count} points"
