Utils = require '../utils'
Registry = require '../registry'
CSSPolyfill = require '../css_polyfill'
BaseElement = require './base'

module.exports = class BoundElement extends BaseElement
  boundCallback: =>
    @_initializeProps()
    @attachShadow({ mode: 'open' })
    @_appendStyles()

    try
      @__component = new @__component_type(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@__component_type.tag)}:", err
    @propertyChange = @__component.onPropertyChange
    setTimeout =>
      return if @__released
      @__component.onMounted?(@)
    , 0

    return unless template = @__component_type.template
    CSSPolyfill.html(template, @__component.css_id) if @__component.css_id
    el = document.createElement('div')
    el.innerHTML = template
    @__component.bindDom(el, @__component)
    nodes = Array::slice.call(el.childNodes)
    @shadowRoot.appendChild(node) while node = nodes?.shift()
    return

  connectedCallback: ->
    # check that infact it connected since polyfill sometimes double calls
    if Utils.connectedToDOM(@) and not @__component
      Utils.scheduleMicroTask =>
        @__component_type?::bindDom(@, @context or {}) unless @__component
        delete @context

  disconnectedCallback: ->
    # prevent premature releasing when element is only temporarely removed from DOM
    Utils.scheduleMicroTask =>
      return if Utils.connectedToDOM(@)
      while node = @shadowRoot?.firstChild
        @__component?.unbindDom(node)
        @shadowRoot.removeChild(node)
      @__component_type?::unbindDom(@)
      if @__component
        @__component.onRelease?(@)
        delete @__component
        @__released = true
