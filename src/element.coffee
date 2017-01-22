Utils = require './utils'
ComponentParser = require './css_parser'
{Parser, Stringifier} = require 'shady-css-parser'

module.exports = class BaseElement extends HTMLElement
  constructor: ->
    # Safari 9 fix
    return HTMLElement.apply(@, arguments)

  boundCallback: =>
    @props = Utils.cloneProps(@__component_type.props)
    @__updating = {}
    for key, prop of @props then do (key, prop) =>
      @props[key].value = Utils.parseAttributeValue(attr) if (attr = @getAttribute(prop.attribute))?
      @props[key].value = value if (value = @[key])?
      @setAttribute(prop.attribute, reflected) if reflected = Utils.reflect(@props[key].value)
      Object.defineProperty @, key, {
        get: ->  @props[key].value
        set: (val) ->
          @__updating[key] = true
          @props[key].value = val
          @setAttribute(prop.attribute, reflected) if reflected = Utils.reflect(val)
          @propertyChange?(key, val)
          delete @__updating[key]
      }

    try
      @__component = new @__component_type(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@__component_type.tag)}:", err

    @propertyChange = @__component.onPropertyChange
    setTimeout =>
      return if @__released
      @__component.onMounted?(@)
    , 0

    if Utils.useShadowDOM
      @attachShadow({ mode: 'open' })
      @shadowRoot.host or= @

    if styles = @__component_type.styles
      if Utils.useShadowDOM
        script = document.createElement('style')
        script.textContent = styles
        @shadowRoot.appendChild(script)
      # append globally otherwise
      else if not document.head.querySelector('#style-' + @__component_type.tag)
        parser = new Parser(new ComponentParser(@__component_type.tag))
        parsed = parser.parse(styles)
        styles = (new Stringifier()).stringify(parsed)
        script = document.createElement('style')
        script.id = 'style-' + @__component_type.tag
        script.textContent = styles
        document.head.appendChild(script)

    if Utils.useShadowDOM
      nodes = @__component.renderTemplate(@__component_type.template, @__component)
      @shadowRoot.appendChild(node) while node = nodes[0]
    else
      root = document.createElement('_root_')
      root.innerHTML = @__component_type.template

      # slot replacement algorithm
      for node in root.querySelectorAll('slot')
        nodes = @childNodes
        nodes = @querySelectorAll("[slot='#{selector}']") if selector = node.getAttribute('name')
        nodes = Array::slice.call(nodes)
        if nodes.length
          node.removeChild(child) while child = node.firstChild
          node.appendChild(child) while child = nodes?.shift()
          node.setAttribute('assigned','')
      @removeChild(child) while child = @firstChild
      @appendChild(root)
    return

  connectedCallback: ->
    if (context = @context) or @getAttribute('data-root')?
      @__component_type::bindDom(@, context or {})
    delete @context

  disconnectedCallback: ->
    if Utils.useShadowDOM
      while node = @shadowRoot?.firstChild
        @__component?.unbindDom(node)
        @shadowRoot.removeChild(node)
    @__component?.onRelease?(@)
    delete @__component
    @__released = true

  attributeChangedCallback: (name, old_val, new_val) ->
    # hasAttribute check is to avoid false nulls for frameworks that bind directly to attributes
    return unless @props and @hasAttribute(name)
    name = @lookupProp(name)
    return if @__updating[name]
    @[name] = Utils.parseAttributeValue(new_val) if name of @props

  lookupProp: (attr_name) ->
    return unless props = @__component_type.props
    return k for k, v of props when attr_name in [k, v.attribute]

  createEvent: (name, params) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail)
    return event