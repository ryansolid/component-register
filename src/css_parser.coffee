{NodeFactory} = require 'shady-css-parser'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
ATTR_MATCHER = /:[a-zA-Z0-9_\-]+|([.#]?[a-zA-Z0-9_\-\*]+)/g

# used to approximate shadow dom css encapsulation
module.exports = class ComponentParser extends NodeFactory
  constructor: (@tag_name, @identifier) ->
  ruleset: (selector, rulelist) ->
    parts = selector.split(',')
    for part, i in parts
      parts[i] = switch
        when part.indexOf('::slotted') isnt -1
          part.replace SLOTTED, (m, c, expr) => @tag_name + ' > ' + expr
        when part.indexOf(':host-context') isnt -1
          part.replace(HOSTCONTEXT, (m, c, expr) => "#{@tag_name}#{expr}") +
            part.replace(HOSTCONTEXT, (m, c, expr) => ", #{expr} #{@tag_name}")
        when part.indexOf(':host(') isnt -1
          part.replace(HOST, (m, c, expr) => "#{@tag_name}#{expr}")
        when part.indexOf('%') is -1 and part.indexOf('to') isnt 0 and part.indexOf('from') isnt 0
          part = part.replace(ATTR_MATCHER, (m, c) =>
            return m unless c
            c + "[#{@identifier}]")
          @tag_name + ' ' + part.replace(':host', '')
        else part
    selector = parts.join(',')
    rulelist.tag_name = @tag_name
    super(selector, rulelist)

  # Probably not needed anymore
  # atRule: (name, parameters, rulelist) ->
  #   # prevent non-media at rules from being scoped
  #   if name.indexOf('media') is -1
  #     for rule in rulelist.rules when rule.selector
  #       rule.selector = rule.selector.replace(rule.rulelist.tag_name + ' ', '')
  #   super