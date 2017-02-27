Utils = require './utils'
ComponentParser = require './css_parser'
HTMLParse = require './html_parser'
{Parser, Stringifier} = require 'shady-css-parser'
COUNTER = 0

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

    if Utils.useShadowDOM
      @attachShadow({ mode: 'open' })
      @shadowRoot.host or= @
      @childRoot = @shadowRoot
    else
      @childRoot = document.createElement('_root_')

    try
      @__component = new @__component_type(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@__component_type.tag)}:", err

    @propertyChange = @__component.onPropertyChange
    setTimeout =>
      return if @__released
      @__component.onMounted?(@)
    , 0

    script = @appendStyles()
    return unless template = @__component_type.template
    template = HTMLParse(template, script.id) if script and (not Utils.useShadowDOM or Utils.polyfillCSS)

    if Utils.useShadowDOM
      nodes = @__component.renderTemplate(template, @__component)
      @shadowRoot.appendChild(node) while node = nodes?.shift()
    else
      @childRoot.innerHTML = template
      # slot replacement algorithm
      slots = Array::slice.call(@childRoot.querySelectorAll('slot[name]'))
      slots = slots.concat(Array::slice.call(@childRoot.querySelectorAll('slot:not([name])')))
      for node in slots
        nodes = @childNodes
        nodes = @querySelectorAll("[slot='#{selector}']") if selector = node.getAttribute('name')
        nodes = Array::slice.call(nodes)
        if nodes.length
          node.removeChild(child) while child = node.firstChild
          node.appendChild(child) while child = nodes?.shift()
          node.setAttribute('assigned','')
      @removeChild(child) while child = @firstChild
      @appendChild(@childRoot)
    return

  connectedCallback: ->
    if (context = @context) or @getAttribute('data-root')? or @__component_type?::auto_bind
      @__component_type::bindDom(@, context or {})
      @removeAttribute('data-root')
    delete @context

  disconnectedCallback: ->
    if Utils.useShadowDOM
      while node = @shadowRoot?.firstChild
        @__component?.unbindDom(node)
        @shadowRoot.removeChild(node)
    if @__component
      @__component?.onRelease?(@)
      delete @__component
      @__released = true

  attributeChangedCallback: (name, old_val, new_val) ->
    # hasAttribute check is to avoid false nulls for frameworks that bind directly to attributes
    return unless @props and @hasAttribute(name)
    name = @lookupProp(name)
    return if @__updating[name]
    @[name] = Utils.parseAttributeValue(new_val) if name of @props

  appendStyles: =>
    if styles = @__component_type.styles
      if Utils.useShadowDOM and not Utils.polyfillCSS
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.textContent = styles
        @shadowRoot.appendChild(script)
        return script
      # append globally otherwise
      scope = @__component_type.tag
      scope += '-' + @__component_type.css_scope if @__component_type.css_scope
      unless script = document.head.querySelector("[scope='#{scope}']")
        @childRoot.cssIdentifier = identifier = "_co#{COUNTER++}"
        host_identifier = attr.name for attr in @attributes when attr.name.indexOf('_co') is 0
        parser = new Parser(new ComponentParser(@__component_type.tag, identifier, host_identifier))
        parsed = parser.parse(styles)
        styles = (new Stringifier()).stringify(parsed)
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.setAttribute('scope', scope)
        script.id = identifier
        script.textContent = styles
        document.head.appendChild(script)
      return script

  lookupProp: (attr_name) ->
    return unless props = @__component_type.props
    return k for k, v of props when attr_name in [k, v.attribute]

  createEvent: (name, params) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail)
    return event