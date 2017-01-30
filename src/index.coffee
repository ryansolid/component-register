# polyfills
require './shims'
require 'document-register-element'
require './component_element'
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

  create: (tag, options) ->
    element = document.createElement(tag)
    if options.attributes
      for k, v of options.attributes
        v = JSON.stringify(v) unless Utils.isString(v)
        element.setAttribute(k, v)
    if options.properties
      element[k] = v for k, v of options.properties
    if options.events
      element.addEventListener(k, v) for k, v of options.events
    if options.template
      element.innerHTML = options.template
    if options.context
      element.context = options.context
    return element