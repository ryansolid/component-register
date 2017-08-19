Utils = require '../utils'
CSSPolyfill = require '../css_polyfill'
COUNTER = 0

module.exports = class BaseElement extends HTMLELement
  connectedCallback: ->
    # check that infact it connected since polyfill sometimes double calls
    return unless Utils.connectedToDOM(@) and not @__component
    @_initializeProps()
    @attachShadow({ mode: 'open' })
    @_appendStyles()
    try
      @__component = new @__component_type(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@__component_type.tag)}:", err

    @propertyChange = @__component.onPropertyChange
    @__component.onRender?(@)
    @__component.onMounted?(@)

  disconnectedCallback: ->
     # prevent premature releasing when element is only temporarely removed from DOM
    Utils.scheduleMicroTask =>
      return if Utils.connectedToDOM(@)
      # @shadowRoot.removeChild(node) while node = @shadowRoot?.firstChild
      if @__component
        @__component.onRelease?(@)
        delete @__component
        @__released = true

  attributeChangedCallback: (name, old_val, new_val) ->
    return unless @props
    return if @__updating[name]
    name = @lookupProp(name)
    if name of @props
      return if new_val is null and not @[name]
      @[name] = Utils.parseAttributeValue(new_val)

  lookupProp: (attr_name) ->
    return unless props = @__component_type.props
    return k for k, v of props when attr_name in [k, v.attribute]

  createEvent: (name, params) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail)
    return event

  _initializeProps: ->
    @props = Utils.cloneProps(@__component_type.props)
    @__updating = {}
    for key, prop of @props then do (key, prop) =>
      @props[key].value = Utils.parseAttributeValue(attr) if (attr = @getAttribute(prop.attribute))?
      if (value = @[key])?
        @props[key].value = if Array.isArray(value) then value[..] else value
      Utils.reflect(@, prop.attribute, @props[key].value)
      Object.defineProperty @, key, {
        get: ->  @props[key].value
        set: (val) ->
          return if Utils.isEqual(val, @props[key].value)
          if Array.isArray(val)
            @props[key].value = val[..]
          else @props[key].value = val
          Utils.reflect(@, prop.attribute, @props[key].value)
          @propertyChange?(key, val)
      }

  _appendStyles: ->
    if styles = @__component_type.styles
      unless Utils.polyfillCSS
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.textContent = styles
        @shadowRoot.appendChild(script)
        return
      # append globally otherwise
      scope = @__component_type.tag
      scope += '-' + @__component_type.css_scope if @__component_type.css_scope
      unless script = document.head.querySelector("[scope='#{scope}']")
        @__component.css_id = "_co#{COUNTER++}"
        styles = CSSPolyfill.css(@__component_type,  @__component.css_id, styles)
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.setAttribute('scope', scope)
        script.id = @__component.css_id
        script.textContent = styles
        document.head.appendChild(script)
      return