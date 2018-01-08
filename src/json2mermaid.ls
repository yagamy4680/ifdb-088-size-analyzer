#
# Copyright 2014-2017 T2T Inc. All rights reserved.
#
require! <[fs]>
{Transform} = require \./helpers/common

const NAME = \json2mermaid


module.exports = exports =
  command: NAME
  describe: "process the number of points in those series in a given json file, to produce a tree structure in DOT format."

  builder: (yargs) ->
    yargs
      .alias \f, \file
      .describe \f, 'the path to json file.'
      .alias \d, \depth
      .describe \d, 'the depth of sensor tree for these series to process'
      .default \d, 3
      .alias \o, \output
      .describe \o, 'the path of mermaid format file as output'
      .alias 'h', 'help'
      .demand <[f d o]>
      .example """
          analyzer #{NAME} --file ./F00010003.json --depth 2 --output /tmp/aa.txt
      """
      .epilogue """
          After produing the mermaid text file, you can use following 2 commands to generate graphics:

            mermaid -s -o /tmp /tmp/aa.txt && open -a "Google Chrome" /tmp/aa.txt.svg
            mermaid -p -o /tmp /tmp/aa.txt && open /tmp/aa.txt.png
      """


  handler: (argv) ->
    {file, depth, output} = argv
    console.log "file => #{file}"
    console.log "depth => #{depth}"
    t = new Transform {}
    (process-err, text) <- t.process file, depth
    return console.error process-err if process-err?
    (write-err) <- fs.writeFile output, text
    return console.error write-err if write-err?
    console.log text
    console.log "written to #{output}"

