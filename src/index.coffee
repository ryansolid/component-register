Utils = require './utils'

module.exports =
  Element: require './element'
  Component: require './component'
  Registry: Registry = {}
  Utils: Utils

  registerComponent: (Component) ->
    return console.error 'Component missing static tag property' unless tag = Component?.tag
    Utils.normalizePropDefs(Component.props)
    element = class CustomElement extends Component::ElementType
      ComponentType: Component
      @observedAttributes: (prop.attribute for name, prop of Component.props)
    Registry[Utils.toComponentName(Component.tag.toLowerCase())] = Component
    customElements.define(Component.tag, element)
    Component