div = document.createElement('div');
shadowDOMV1 = !!div.attachShadow;
customProperties = window.CSS and CSS.supports('color', 'var(--primary)')

module.exports = class ComponentUtils
  @useShadowDOM: shadowDOMV1
  @polyfillCSS: !shadowDOMV1
  @excludeTags = []

  @normalizePropDefs: (props) ->
    return unless props
    for k, v of props
      unless ComponentUtils.isObject(v) and 'value' of v
        props[k] = {value: v}
      props[k].notify ?= false
      props[k].attribute or= ComponentUtils.toAttribute(k)
    return

  @cloneProps: (props) ->
    new_props = {}
    for k, prop of props
      new_props[k] = Object.assign({}, prop)
      new_props[k].value = Object.assign({}, prop.value) if ComponentUtils.isObject(prop.value) and not ComponentUtils.isFunction(prop.value) and not Array.isArray(prop.value)
      new_props[k].value = prop.value[..] if Array.isArray(prop.value)
    new_props

  @propValues: (props) ->
    values = {}
    values[k] = prop.value for k, prop of props
    values

  # shallow diff and order matters
  @arrayDiff: (array1, array2) ->
    return true unless array1.length is array2.length
    return true for item, i in array1 when item isnt array2[i]
    false

  @toAttribute: (prop_name) -> prop_name.replace(/_/g, '-').toLowerCase()
  @toProperty: (prop_name) -> prop_name.replace(/-/g, '_')
  @toComponentName: (tag) -> tag?.toLowerCase().replace(/(^|-)([a-z])/g, (test) -> test.toUpperCase().replace('-',''))
  @toTagName: (component_name) -> component_name.replace(/\.?([A-Z]+)/g, (x,y) ->  "-" + y.toLowerCase()).replace(/^-/, "")

  @parseAttributeValue: (value) ->
    return unless value
    try
      parsed = JSON.parse(value)
    catch err
      parsed = value
    return parsed unless typeof parsed is 'string'
    return +parsed if /^[0-9]*$/.test(parsed)
    parsed

  @reflect: (node, attribute, value) ->
    if not ComponentUtils.isObject(value) and (reflect = value?.toString?()) and reflect isnt 'false'
      node.__updating[attribute] = true
      reflect = '' if reflect is 'true'
      node.setAttribute(attribute, reflect)
      ComponentUtils.scheduleMicroTask -> delete node.__updating[attribute]
    else node.removeAttribute(attribute)

  @isObject: (obj) -> obj isnt null and typeof obj in ['object', 'function']

  @isFunction: (val) -> Object::toString.call(val) is "[object Function]"

  @isString: (val) -> Object::toString.call(val) is "[object String]"

  @connectedToDOM: (node) ->
    return node.isConnected if 'isConnected' of node
    return true if document.body.contains(node)
    return false unless ComponentUtils.useShadowDOM
    null while (node = node.parentNode or node.host) and node isnt document.documentElement
    node is document.documentElement

  @scheduleMicroTask: do ->
    # use promises if available or fallback to MutationObserver
    if (window.Promise)
      return (callback) -> Promise.resolve().then(callback)

    # Using 2 mutation observers to batch multiple updates into one.
    div = document.createElement('div')
    options = {attributes: true}
    toggle_scheduled = false
    div2 = document.createElement('div')
    o2 = new MutationObserver ->
      div.classList.toggle('foo')
      toggle_scheduled = false
      return
    o2.observe(div2, options)

    scheduleToggle = ->
      return if toggle_scheduled
      toggle_scheduled = true
      div2.classList.toggle('foo')
      return

    (callback) ->
      o = new MutationObserver ->
        o.disconnect()
        callback()
        return
      o.observe(div, options)
      scheduleToggle()
