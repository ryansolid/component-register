{NodeFactory, Parser, Stringifier} = require 'shady-css-parser'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
ATTR_MATCHER = /[\[\(][^)\]]+[\]\)]|:[a-zA-Z0-9_\-]+|([.#]?[a-zA-Z0-9_\-\*]+)/g

# used to approximate shadow dom css encapsulation
class ComponentParser extends NodeFactory
  constructor: (@tagName, @identifier) ->

  ruleset: (selector, rulelist) ->
    parts = selector.split(',')

    # replace shadow dom selectors
    for part, i in parts when part.indexOf('%') is -1 and not (part.trim() in ['to', 'from'])
      if @identifier
        part = part.replace(ATTR_MATCHER, (m, c) =>
          return m unless c
          c + "[#{@identifier}]")
      if part.indexOf('::slotted') isnt -1
        part = part.replace SLOTTED, (m, expr) => " > #{expr}"
        part += ":not([#{@identifier}])" if @identifier
      parts[i] = switch
        when part.indexOf(':host-context') isnt -1
          part.replace(HOSTCONTEXT, (m, c, expr) => "#{@tagName}#{expr}") +
            part.replace(HOSTCONTEXT, (m, c, expr) => ", #{expr} #{@tagName}")
        when part.indexOf(':host(') isnt -1
          part.replace(HOST, (m, c, expr) => "#{@tagName}#{expr}")
        else @tagName + ' ' + part.replace(':host', '')
    selector = parts.join(',')
    super(selector, rulelist)

module.exports = (scope, styles, identifier) ->
  parser = new Parser(new ComponentParser(scope, identifier))
  parsed = parser.parse(styles)
  return (new Stringifier()).stringify(parsed)