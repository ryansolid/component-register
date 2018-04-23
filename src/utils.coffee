div = document?.createElement('div');
shadowDOMV1 = !!div?.attachShadow;

export default {
  nativeShadowDOM: shadowDOMV1

  normalizePropDefs: (props) ->
    return unless props
    for k, v of props
      unless ComponentUtils.isObject(v) and 'value' of v
        props[k] = {value: v}
      props[k].notify ?= false
      props[k].attribute or= ComponentUtils.toAttribute(k)
    return

  cloneProps: (props) ->
    newProps = {}
    for k, prop of props
      newProps[k] = {prop...}
      newProps[k].value ={prop.value...} if ComponentUtils.isObject(prop.value) and not ComponentUtils.isFunction(prop.value) and not Array.isArray(prop.value)
      newProps[k].value = prop.value[..] if Array.isArray(prop.value)
    newProps

  propValues: (props) ->
    values = {}
    values[k] = prop.value for k, prop of props
    values

  # deepEqual
  isEqual: (x, y, xStack=[], yStack=[]) ->
    return true if x is y

    dateA = x instanceof Date
    dateB = y instanceof Date
    return x.getTime() is y.getTime() if dateA and dateB
    return false if dateA != dateB

    keys = Object.keys; tx = typeof x; ty = typeof y
    if x and y and tx is 'object' and tx is ty
      # handle circular dependencies
      length = xStack.length;
      while length--
        return yStack[length] is y if xStack[length] is x
      xStack.push(x)
      yStack.push(y)
      equal = keys(x).length is keys(y).length and keys(x).every (key) ->
        ComponentUtils.isEqual(x[key], y[key], xStack, yStack)
      xStack.pop()
      yStack.pop()
      return equal
    x is y

  toAttribute: (propName) -> propName.replace(/\.?([A-Z]+)/g, (x,y) ->  "-" + y.toLowerCase()).replace('_','-').replace(/^-/, "")
  toProperty: (attr) -> attr?.toLowerCase().replace(/(-)([a-z])/g, (test) -> test.toUpperCase().replace('-',''))
  toComponentName: (tag) -> tag?.toLowerCase().replace(/(^|-)([a-z])/g, (test) -> test.toUpperCase().replace('-',''))

  parseAttributeValue: (value) ->
    return unless value
    try
      parsed = JSON.parse(value)
    catch err
      parsed = value
    return parsed unless typeof parsed is 'string'
    return +parsed if /^[0-9]*$/.test(parsed)
    parsed

  reflect: (node, attribute, value) ->
    return if ComponentUtils.isObject(value)
    if (reflect = value?.toString?()) and reflect isnt 'false'
      node.__updating[attribute] = true
      reflect = '' if reflect is 'true'
      node.setAttribute(attribute, reflect)
      Promise.resolve().then -> delete node.__updating[attribute]
    else node.removeAttribute(attribute)

  isObject: (obj) -> obj isnt null and typeof obj in ['object', 'function']

  isFunction: (val) -> Object::toString.call(val) is "[object Function]"

  isString: (val) -> Object::toString.call(val) is "[object String]"

  isConstructor: (f) ->
    return typeof f is 'function' and f.toString().indexOf('class') is 0

  connectedToDOM: (node) ->
    return node.isConnected if 'isConnected' of node
    return true if document.body.contains(node)
    null while (node = node.parentNode or node.host) and node isnt document.documentElement
    node is document.documentElement
}
