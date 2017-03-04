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
      @childRoot = @shadowRoot
    else
      @childRoot = document.createElement('_root_')
      #disconnect childnodes
      fragment = document.createDocumentFragment()
      fragment.appendChild(node) while node = @firstChild
      @processSlots(fragment)
    @childRoot.host or= @

    try
      @__component = new @__component_type(@, Utils.propValues(@props))
    catch err
      console.error "Error creating component #{Utils.toComponentName(@__component_type.tag)}:", err

    @propertyChange = @__component.onPropertyChange
    mounted_observer = new MutationObserver(Utils.debounce 10, =>
      return if @__released
      mounted_observer.disconnect()
      @__component.onMounted?(@)
    )
    mounted_observer.observe(@childRoot, {childList: true, subtree: true})

    # slot assignment for non-shadow dom
    if !Utils.useShadowDOM and fragment.childNodes.length
      slot_observer = new MutationObserver (mutations) =>
        return if @__released
        for mutation in mutations when mutation.addedNodes.length
          continue unless Utils.inComponent(mutation.addedNodes[0], @)
          slots = @findSlots(mutation.addedNodes)
          @assignSlot(slot) for slot in slots
      slot_observer.observe(@childRoot, {childList: true, subtree: true})

    script = @appendStyles()
    return unless template = @__component_type.template
    template = HTMLParse(template, script.id) if script and (not Utils.useShadowDOM or Utils.polyfillCSS)
    nodes = @__component.renderTemplate(template, @__component)
    @childRoot.appendChild(node) while node = nodes?.shift()
    return if Utils.useShadowDOM
    @appendChild(@childRoot)

  connectedCallback: ->
    # check that infact it connected since polyfill sometimes double calls
    if Utils.connectedToDOM(@)
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
    # hasAttribute check is to avoid false nulls for frameworks that bind directly to attributes
    # return unless @props and @hasAttribute(name)
    name = @lookupProp(name)
    return if @__updating[name]
    @[name] = Utils.parseAttributeValue(new_val) if name of @props

  processSlots: (fragment) =>
    @__assignableNodes = {}
    for node in fragment.querySelectorAll("[slot]")
      name = node.getAttribute('slot')
      @__assignableNodes[name] or= []
      @__assignableNodes[name].push(node)

    default_slot = []
    default_slot.push(node) for node in fragment.childNodes when not node.hasAttribute?('slot')
    @__assignableNodes['_default'] = default_slot

  findSlots: (nodes) =>
    slots = []
    for node in nodes
      switch node.nodeName
        when 'SLOT' then slots.push(node)
        when '_ROOT_' then continue
        else
          slots.push.apply(slots, @findSlots(node.childNodes)) if node.childNodes.length
    return slots

  assignSlot: (slot) =>
    name = slot.getAttribute('name')
    name = '_default' unless name
    if nodes = @__assignableNodes[name]
      slot.removeChild(child) while child = slot.firstChild
      slot.appendChild(child) for child in nodes
      slot.setAttribute('assigned','')

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
    return unless @props
    return unless props = @__component_type.props
    return k for k, v of props when attr_name in [k, v.attribute]

  createEvent: (name, params) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail)
    return event