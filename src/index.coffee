Utils = require './utils'

module.exports =
  Element: require './element'
  Component: require './component'
  Registry: Registry = {}
  Utils: Utils

  registerComponent: (component) ->
    return console.error 'Component missing static tag property' unless tag = component?.tag
    Utils.normalizePropDefs(component.props)
    element = class CustomElement extends component::element_type
      __component_type: component
      @observedAttributes: (prop.attribute for name, prop of component.props)
    Registry[Utils.toComponentName(component.tag.toLowerCase())] = component
    customElements.define(component.tag, element)
    component