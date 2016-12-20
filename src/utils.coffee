div = document.createElement('div');
shadowDOMV1 = !!div.attachShadow;

# force polyfill on Safari's poor Shadow Dom implementation (missing host styles)
# is_safari = navigator.userAgent.toLowerCase().indexOf('safari/') > -1 and navigator.userAgent.toLowerCase().indexOf('chrome/') is -1

### force polyfill until browsers are consistent ###
{v1} = require 'skatejs-named-slots'
v1() if shadowDOMV1 # if is_safari
require 'document-register-element'

module.exports = class ComponentUtils
  @nativeShadowDOM: false #shadowDOMV1 and not is_safari

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
      new_props[k] = ComponentUtils.shallowClone(prop)
      new_props[k].value = ComponentUtils.shallowClone(prop.value) if ComponentUtils.isObject(prop.value) and not ComponentUtils.isFunction(prop.value)
    new_props

  @propValues: (props) ->
    values = {}
    values[k] = prop.value for k, prop of props
    values

  @toAttribute: (prop_name) -> prop_name.replace(/_/g, '-').toLowerCase()
  @toEventName: (prop_name) -> prop_name.replace(/_/g, '').toLowerCase()
  @toComponentName: (tag) -> tag?.toLowerCase().replace(/(^|-)([a-z])/g, (test) -> test.toUpperCase().replace('-',''))

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

  @shallowClone: (old_obj) ->
    new_obj = {}
    for i of old_obj when old_obj.hasOwnProperty(i)
      new_obj[i] = old_obj[i]
    new_obj
