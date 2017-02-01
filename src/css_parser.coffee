{NodeFactory} = require 'shady-css-parser'
Registry = require './registry'
Utils = require './utils'
SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/
ATTR_MATCHER = /[\[\(].+[\]\)]|:[a-zA-Z0-9_\-]+|([.#]?[a-zA-Z0-9_\-\*]+)/g
VAR_RULE = /^var\(([a-zA-Z0-9\-_]+),?\s*(.*)\)/

VARIABLE_CONTEXT = {}

# used to approximate shadow dom css encapsulation
module.exports = class ComponentParser extends NodeFactory
  constructor: (@tag_name, @identifier, @host_identifier) ->
    @tag_names = Registry.registeredTags() if Utils.polyfillCustomProperties
  ruleset: (selector, rulelist) ->
    parts = selector.split(',')

    # Currently IE and Edge, although Edge support is coming soon
    # minimal support only handling the case of styling elements from the outside
    if Utils.polyfillCustomProperties
      # parse custom vars
      if (var_rules = rulelist.rules.filter((rule)-> rule.name.indexOf('--') is 0)).length
        for tag in @tag_names when selector.indexOf(tag) isnt -1
          VARIABLE_CONTEXT[tag+@identifier] or= {}
          VARIABLE_CONTEXT[tag+@identifier][rule.name] = rule.value.text for rule in var_rules

      # replace custom vars
      if (var_rule_vals = rulelist.rules.filter((rule) -> rule.value?.text?.indexOf('var') is 0)).length
        for rule in var_rule_vals
          var_match = rule.value.text.match(VAR_RULE)
          rule.value.text = VARIABLE_CONTEXT[@tag_name+@host_identifier]?[var_match[1]] or var_match[2]

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