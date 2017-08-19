Element = require './base'
Registry = require '../registry'
TAG = 'component-element'

class ComponentElement extends Element
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