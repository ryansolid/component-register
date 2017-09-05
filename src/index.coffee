# polyfills
require './shims'
require './elements/component_element'
Utils = require './utils'

module.exports =
  Element: require './element'
  Component: require './component'
  Registry: registry = require './registry'
  Utils: Utils

  registerComponent: (component) ->
    Utils.normalizePropDefs(component.props)
    element = class CustomElement extends component::element_type
      __component_type: component
      @observedAttributes: (prop.attribute for name, prop of component.props)
      constructor: ->
        # Safari 9 fix
        return component::element_type.apply(@, arguments)
    registry.register(component)
    customElements.define(component.tag, element)
    component