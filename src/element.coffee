Utils = require './utils'
CSSPolyfill = require './css_polyfill'
COUNTER = 0

module.exports = class BaseElement extends HTMLElement
  connectedCallback: ->
    # check that infact it connected since polyfill sometimes double calls
    return unless Utils.connectedToDOM(@) and not @component
    @_initializeProps()
    @attachShadow({ mode: 'open' })
    try
      @component = new @ComponentType(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@ComponentType.tag)}:", err

    @propertyChange = @component.onPropertyChange
    @_appendStyles()
    @component.onRender?(@)
    @component.onMounted?(@)

  disconnectedCallback: ->
     # prevent premature releasing when element is only temporarely removed from DOM
    Utils.scheduleMicroTask =>
      return if Utils.connectedToDOM(@)
      if @component
        @component.onRelease?(@)
        delete @component
        @__released = true

  attributeChangedCallback: (name, old_val, new_val) ->
    return unless @props
    return if @__updating[name]
    name = @lookupProp(name)
    if name of @props
      return if new_val is null and not @[name]
      @[name] = Utils.parseAttributeValue(new_val)

  lookupProp: (attr_name) ->
    return unless props = @ComponentType.props
    return k for k, v of props when attr_name in [k, v.attribute]

  _initializeProps: ->
    @props = Utils.cloneProps(@ComponentType.props)
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
    if styles = @ComponentType.styles
      unless Utils.polyfillCSS
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.textContent = styles
        @shadowRoot.appendChild(script)
        return
      # append globally otherwise
      scope = @ComponentType.tag
      unless script = document.head.querySelector("[scope='#{scope}']")
        @component.cssId = "_co#{COUNTER++}"
        styles = CSSPolyfill.css(scope, styles, if @ComponentType::scopeCSS then @component.cssId else undefined)
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.setAttribute('scope', scope)
        script.id = @component.cssId
        script.textContent = styles
        document.head.appendChild(script)
      else @component.cssId = script.id
      return