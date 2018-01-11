#
# Copyright 2014-2017 T2T Inc. All rights reserved.
#
require! <[lodash fs path]>


ADD = (a, b) -> return a + b


class Series
  (@ns, @count, @transform) ->
    {series-list, root} = transform
    series-list.push @
    current = root
    current.add-count count
    for name in ns
      c = current.get-child name
      c.add-count count
      current := c

  to-text: -> return "#{@ns.join '.'} => #{@count}"


class Node
  (@name, @parent, @transform) ->
    @index = transform.get-next-index!
    @children = {}
    @count = 0
    return

  get-child: (name) ->
    {children, transform} = self = @
    c = children[name]
    return c if c?
    c = new Node name, self, transform
    # console.log "[#{self.name}] add #{name}"
    self.children[name] = c

  add-count: (x) ->
    @count = @count + x

  get-count: ->
    return @count

  get-name: ->
    return @name

  to-text: (leaf=no) ->
    {index, name, count, transform} = self = @
    {root} = transform
    percentages = Math.floor ((count * 100) / root.count)
    return "n#{index}(#{name}: #{count})" if count is root.count
    return "n#{index}(#{name}: #{count})" if leaf
    return "n#{index}(#{name}: #{percentages}%)"


class Transform
  (@opts) ->
    self = @
    self.index = 0
    self.root = new Node \root, null, self
    self.series-list = []
    self.reset-outputs!
    return

  reset-outputs: ->
    @outputs = []

  get-next-index: ->
    {index} = self = @
    self.index = index + 1
    return self.index

  print-output-line: (line) ->
    {outputs} = self = @
    return outputs.push line

  process-series: (data) ->
    {root} = self = @
    {name, columns, points} = data
    xs = [ x[1] for x in points ]
    xs = xs.reduce ADD, 0
    ns = name.split '/'
    y = ns.shift!
    s = new Series ns, xs, self
    root.name = y

  process: (@file, done) ->
    {opts, root} = self = @
    try
      json = require file
    catch error
      return done error
    [ self.process-series d for d in json ]
    return done!

  traverse-tree: (depth, done) ->
    {root} = self = @
    try
      self.reset-outputs!
      self.print-output-line "graph LR;"
      self.traverse-tree-internally root, depth
    catch error
      return done error
    self.count = self.root.get-count!
    text = self.outputs.join '\n'
    return done null, text

  traverse-tree-internally: (parent, depth) ->
    self = @
    return if depth is 0
    for name, c of parent.children
      self.print-output-line "\t#{parent.to-text!} --> #{c.to-text (depth is 1)}"
    for name, c of parent.children
      self.traverse-tree-internally c, depth - 1

  get-total-count: ->
    return @root.get-count!

  get-total-series: ->
    return @series-list.length

  get-id: ->
    return @root.get-name!


module.exports = exports = {Transform, ADD}
