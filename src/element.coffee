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
      Utils.reflect(@, prop.attribute, @props[key].value)
      Object.defineProperty @, key, {
        get: ->  @props[key].value
        set: (val) ->
          @props[key].value = val
          Utils.reflect(@, prop.attribute, @props[key].value)
          @propertyChange?(key, val)
      }

    if Utils.useShadowDOM
      @attachShadow({ mode: 'open' })
      @childRoot = @shadowRoot
    else
      @childRoot = document.createElement('_root_')
      #disconnect childnodes
      fragment = document.createDocumentFragment()
      fragment.appendChild(node) while node = @firstChild
    @childRoot.host or= @

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
      @assignSlots(fragment)
      @markDefered(@childRoot)
      @appendChild(@childRoot)
    return

  connectedCallback: ->
    # check that infact it connected since polyfill sometimes double calls
    if Utils.connectedToDOM(@) and not this.__component and not this.__defer_binding
      @__component_type?::bindDom(@, @context or {})
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
    delete @childRoot
    delete @__assignableNodes

  attributeChangedCallback: (name, old_val, new_val) ->
    return unless @props
    return if @__updating[name]
    name = @lookupProp(name)
    if name of @props
      return if new_val is null and not @[name]
      @[name] = Utils.parseAttributeValue(new_val)

  assignSlots: (fragment) =>
    slots = Array::slice.call(@childRoot.querySelectorAll('slot[name]'))
    slots = slots.concat(Array::slice.call(@childRoot.querySelectorAll('slot:not([name])')))
    for node in slots
      nodes = fragment.childNodes
      nodes = fragment.querySelectorAll("[slot='#{selector}']") if selector = node.getAttribute('name')
      nodes = Array::slice.call(nodes)
      if nodes.length
        node.removeChild(child) while child = node.firstChild
        node.appendChild(child) while child = nodes?.shift()
        node.setAttribute('assigned','')

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
        parser = new Parser(new ComponentParser(@__component_type.tag, identifier))
        parsed = parser.parse(styles)
        styles = (new Stringifier()).stringify(parsed)
        script = document.createElement('style')
        script.setAttribute('type', 'text/css')
        script.setAttribute('scope', scope)
        script.id = identifier
        script.textContent = styles
        document.head.appendChild(script)
      return script

  markDefered: (node) =>
    # polyfilled elements aren't upgraded yet must mark every reasonable element
    node.__defer_binding = true if node.nodeType is 1
    @markDefered(node) for node in node.childNodes
    return

  lookupProp: (attr_name) ->
    return unless props = @__component_type.props
    return k for k, v of props when attr_name in [k, v.attribute]

  createEvent: (name, params) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail)
    return event