{NodeFactory} = require 'shady-css-parser'
Registry = require './registry'
Utils = require './utils'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
ATTR_MATCHER = /[\[\(][^)\]]+[\]\)]|:[a-zA-Z0-9_\-]+|([.#]?[a-zA-Z0-9_\-\*]+)/g

# used to approximate shadow dom css encapsulation
module.exports = class ComponentParser extends NodeFactory
  constructor: (@tag_name, @identifier) ->

  ruleset: (selector, rulelist) ->
    parts = selector.split(',')

    # replace shadow dom selectors
    for part, i in parts when part.indexOf('%') is -1 and not (part.trim() in ['to', 'from'])
      part = part.replace(ATTR_MATCHER, (m, c) =>
        return m unless c
        c + "[#{@identifier}]")
      parts[i] = switch
        when part.indexOf('::slotted') isnt -1
          part.replace SLOTTED, (m, expr) => @tag_name + ' slot > ' + expr
        when part.indexOf(':host-context') isnt -1
          part.replace(HOSTCONTEXT, (m, c, expr) => "#{@tag_name}#{expr}") +
            part.replace(HOSTCONTEXT, (m, c, expr) => ", #{expr} #{@tag_name}")
        when part.indexOf(':host(') isnt -1
          part.replace(HOST, (m, c, expr) => "#{@tag_name}#{expr}")
        else @tag_name + ' ' + part.replace(':host', '')
    selector = parts.join(',')
    super(selector, rulelist)