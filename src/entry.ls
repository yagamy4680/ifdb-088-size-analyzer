#!/usr/bin/env lsc
#
require! <[lodash fs path]>

global.index = 0
global.lines = []

add = (a, b) -> return a + b
get-next-index = ->
  global.index = global.index + 1
  return global.index

output-line = (line) ->
  console.log line
  global.lines.push line


class Series
  (@ns, @count) ->
    {series-list, root} = global
    series-list.push @
    current = root
    current.add-count count
    for name in ns
      c = current.get-child name
      c.add-count count
      current := c

  to-text: -> return "#{@ns.join '.'} => #{@count}"


class Node
  (@name, @parent) ->
    @index = get-next-index!
    @children = {}
    @count = 0
    return

  get-child: (name) ->
    {children} = self = @
    c = children[name]
    return c if c?
    c = new Node name, self
    # console.log "[#{self.name}] add #{name}"
    self.children[name] = c

  add-count: (x) ->
    @count = @count + x

  to-text: (leaf=no) ->
    {index, name, count} = @
    {root} = global
    percentages = Math.floor ((count * 100) / root.count)
    return "n#{index}(#{name}: #{count})" if count is root.count
    return "n#{index}(#{name}: #{count})" if leaf
    return "n#{index}(#{name}: #{percentages}%)"



process-series = (data) ->
  {name, columns, points} = data
  xs = [ x[1] for x in points ]
  xs = xs.reduce add, 0
  ns = name.split '/'
  y = ns.shift!
  s = new Series ns, xs
  global.root.name = y


show-sorted-series = (series-list) ->
  xs = lodash.sortBy series-list, <[count]>
  [ console.log x.to-text! for x in xs ]


traverse-tree = (parent, depth) ->
  return if depth is 0
  for name, c of parent.children
    output-line "\t#{parent.to-text!} --> #{c.to-text (depth is 1)}"
  for name, c of parent.children
    traverse-tree c, depth - 1



global.series-list = []
global.root = new Node \root, null

input = process.argv[2]
dump = require input
[ process-series a for a in dump ]

depth = process.argv[3]
depth = 3 unless depth?
depth = parse-int depth if \string is typeof depth

# show-sorted-series global.series-list


output-line "graph LR;"
traverse-tree global.root, depth

file-path = "/tmp/#{path.basename input}"

(err) <- fs.writeFile file-path, (global.lines.join '\n')
return console.error err if err?
return console.log """

Please run following command to convert the dot file (#{file-path}) to SVG:

    mermaid -s -o /tmp #{file-path} && open -a "Google Chrome" #{file-path}.svg

Or PNG:

    mermaid -p -o /tmp #{file-path} && open #{file-path}.png
"""
/*

*/