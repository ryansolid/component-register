{NodeFactory} = require 'shady-css-parser'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/

# used to approximate shadow dom css encapsulation
module.exports = class ComponentParser extends NodeFactory
  constructor: (@tag_name) ->
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
        else
          @tag_name + ' ' + part.replace(':host', '')
    selector = parts.join(',')
    rulelist.tag_name = @tag_name
    super(selector, rulelist)

  atRule: (name, parameters, rulelist) ->
    # prevent keyframes from being scoped
    if name.indexOf('keyframe') isnt 1
      for rule in rulelist.rules
        rule.selector = rule.selector.replace(rule.rulelist.tag_name + ' ', '')
    super