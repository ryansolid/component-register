import Utils from './utils'

export default ({BaseElement, propDefinition, ComponentType}) ->
  class CustomElement extends BaseElement
    @observedAttributes: (prop.attribute for name, prop of propDefinition)
    connectedCallback: ->
      # check that infact it connected since polyfill sometimes double calls
      return unless Utils.connectedToDOM(@) and not @__initialized
      @_initializeProps()
      @__releaseCallbacks = []
      props = Utils.propValues(@props)
      try
        if Utils.isConstructor(ComponentType)
          new ComponentType({element: @, props})
        else ComponentType({element: @, props})
      catch err
        console.error "Error creating component #{Utils.toComponentName(@nodeName.toLowerCase())}:", err
      @__initialized = true

    disconnectedCallback: ->
      # prevent premature releasing when element is only temporarely removed from DOM
      await Promise.resolve()
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

    renderRoot: -> @shadowRoot or @attachShadow({ mode: 'open' })

    setProperty: (name, value) ->
      return unless name of @props
      prop = @props[name]
      return if prop.value is value and not Array.isArray(value)
      oldValue = prop.value
      prop.value = value
      Utils.reflect(@, prop.attribute, value)
      if prop.notify
        @trigger('propertychange', {detail: {value, oldValue, name}})

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
      return