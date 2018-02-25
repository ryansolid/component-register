import Utils from './utils'
import CSSPolyfill from './css-polyfill'
COUNTER = 0

export default ({BaseElement, propDefinition, ComponentType, childStyles, scopeCSS}) ->
  class CustomElement extends BaseElement
    @observedAttributes: (prop.attribute for name, prop of propDefinition)
    connectedCallback: ->
      # check that infact it connected since polyfill sometimes double calls
      return unless Utils.connectedToDOM(@) and not @__initialized
      @_initializeProps()
      @attachShadow({ mode: 'open' })
      @cssId = @_appendStyles()
      try
        if ComponentTyp::constructor.name
          new ComponentType(@, Utils.propValues(@props))
        else ComponentType(@, Utils.propValues(@props) )
      catch err
        console.error "Error creating component #{Utils.toComponentName(@nodeName.toLowerCase())}:", err

      @__releaseCallbacks = []
      @__initialized = true

    disconnectedCallback: ->
      # prevent premature releasing when element is only temporarely removed from DOM
      Utils.scheduleMicroTask =>
        return if Utils.connectedToDOM(@)
        callback(@) while callback = @__releaseCallbacks.pop()
        @__released = true

    attributeChangedCallback: (name, old_val, new_val) ->
      return unless @props
      return if @__updating[name]
      name = @lookupProp(name)
      if name of @props
        return if new_val is null and not @[name]
        @[name] = Utils.parseAttributeValue(new_val)

    lookupProp: (attr_name) ->
      return unless props = propDefinition
      return k for k, v of props when attr_name in [k, v.attribute]

    setProperty: (name, value) ->
      return unless name of @props
      prop = @props[name]
      return if prop.value is value and not Array.isArray(value)
      oldValue = prop.value
      prop.value = value
      Utils.reflect(@, prop.attribute, value)
      if prop.notify
        @trigger('propertychange', {value, oldValue, name})

    trigger: (name, {detail, bubbles = true, cancelable = true, composed = false}) ->
      event = new CustomEvent(name, {detail, bubbles, cancelable, composed})
      notCancelled = true
      notCancelled = !!@['on'+name]?(event) if @['on'+name]
      notCancelled and !!@dispatchEvent(event)

    addReleaseCallback: (fn) -> @__releaseCallbacks.push(fn)

    _initializeProps: ->
      @props = Utils.cloneProps(propDefinition)
      @__updating = {}
      for key, prop of @props then do (key, prop) =>
        @props[key].value = Utils.parseAttributeValue(attr) if (attr = @getAttribute(prop.attribute))?
        if (value = @[key])?
          @props[key].value = if Array.isArray(value) then value[..] else value
        Utils.reflect(@, prop.attribute, @props[key].value)
        Object.defineProperty @, key, {
          get: -> @props[key].value
          set: (val) ->
            return if Utils.isEqual(val, @props[key].value)
            if Array.isArray(val)
              @props[key].value = val[..]
            else @props[key].value = val
            Utils.reflect(@, prop.attribute, @props[key].value)
            @onPropertyChangedCallback?(key, val)
        }

    _appendStyles: ->
      if styles = childStyles
        unless Utils.polyfillCSS
          script = document.createElement('style')
          script.setAttribute('type', 'text/css')
          script.textContent = styles
          @shadowRoot.appendChild(script)
          return
        # append globally otherwise
        scope = @nodeName.toLowerCase()
        unless script = document.head.querySelector("[scope='#{scope}']")
          cssId = "_co#{COUNTER++}"
          styles = CSSPolyfill.css(scope, styles, if scopeCSS then cssId else undefined)
          script = document.createElement('style')
          script.setAttribute('type', 'text/css')
          script.setAttribute('scope', scope)
          script.id = cssId
          script.textContent = styles
          document.head.appendChild(script)
        else cssId = script.id
        return cssId