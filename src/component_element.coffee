Element = require './element'
Registry = require './registry'
TAG = 'component-element'

class ComponentElement extends Element
  constructor: ->
    # Safari 9 fix
    return Element.apply(@, arguments)

  boundCallback: =>
    @__component_type or= @component
    delete @component
    super

  connectedCallback: =>
    @__component_type or= @component
    delete @component
    super

Registry.register({tag: TAG})
customElements.define(TAG, ComponentElement)