{NodeFactory} = require 'shady-css-parser'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
CLASSNAME = /\.([a-zA-Z0-9_\-]*)/g

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
        else
          @tag_name + ' ' + part.replace(':host', '')
          parts[i] = parts[i].replace(CLASSNAME, "$&[#{@identifier}]")
    selector = parts.join(',')
    rulelist.tag_name = @tag_name
    super(selector, rulelist)

  atRule: (name, parameters, rulelist) ->
    # prevent non-media at rules from being scoped
    if name.indexOf('media') is -1
      for rule in rulelist.rules when rule.selector
        rule.selector = rule.selector.replace(rule.rulelist.tag_name + ' ', '')
    super