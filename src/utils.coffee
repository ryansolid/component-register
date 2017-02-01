div = document.createElement('div');
shadowDOMV1 = !!div.attachShadow;
customProperties = window.CSS and CSS.supports('color', 'var(--primary)')

module.exports = class ComponentUtils
  @useShadowDOM: shadowDOMV1
  @polyfillCSS: !shadowDOMV1
  @polyfillCustomProperties: !customProperties

  @normalizePropDefs: (props) ->
    return unless props
    for k, v of props
      unless ComponentUtils.isObject(v) and 'value' of v
        props[k] = {value: v}
      props[k].notify ?= false
      props[k].event_name or= ComponentUtils.toEventName(k)
      props[k].attribute or= ComponentUtils.toAttribute(k)
    return

  @cloneProps: (props) ->
    new_props = {}
    for k, prop of props
      new_props[k] = Object.assign({}, prop)
      new_props[k].value = Object.assign({}, prop.value) if ComponentUtils.isObject(prop.value) and not ComponentUtils.isFunction(prop.value)
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
  @toEventName: (prop_name) -> prop_name.replace(/_/g, '').toLowerCase()
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

  @reflect: (value) ->
    return unless not ComponentUtils.isObject(value) and reflect = value?.toString?()
    reflect

  @isObject: (obj) -> obj isnt null and typeof obj in ['object', 'function']

  @isFunction: (val) -> Object::toString.call(val) is "[object Function]"

  @isString: (val) -> Object::toString.call(val) is "[object String]"
