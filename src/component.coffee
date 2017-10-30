Utils = require './utils'

module.exports = class Component
  ElementType: require './element'
  scopeCSS: true
  constructor: (@element, props) ->
    @__releaseCallbacks = []
    @displayName = Utils.toComponentName(@constructor.tag)

  setProperty: (name, value) ->
    return unless name of @element.props
    prop = @element.props[name]
    return if prop.value is value and not Array.isArray(value)
    oldValue = prop.value
    prop.value = value
    Utils.reflect(@element, prop.attribute, value)
    if prop.notify
      @trigger('propertychange', {value, oldValue, name})

  onRender: ->
  onMounted: ->
  onPropertyChange: (name, val) ->
  onRelease: ->
    return if @__released
    @__released = true
    callback(@) while callback = @__releaseCallbacks.pop()
    delete @element

  wasReleased: -> !!@__released

  addReleaseCallback: (fn) -> @__releaseCallbacks.push(fn)

  ###############
  # Integration Methods
  # Here to make sure asyncronous operations only last the lifetime of the component
  delay: (delayTime, callback) ->
    [delayTime, callback] = [0, delayTime] if Utils.isFunction(delayTime)
    timer = setTimeout(callback, delayTime)
    @addReleaseCallback -> clearTimeout(timer)
    return timer

  interval: (delayTime, callback) ->
    timer = setInterval(callback, delayTime)
    @addReleaseCallback -> clearInterval(timer)
    return timer

  trigger: (name, detail, options={}) ->
    event = new CustomEvent(name, Object.assign({detail, bubbles: true, cancelable: true}, options))
    notCancelled = true
    notCancelled = !!@element['on'+name]?(event) if @element['on'+name]
    notCancelled and !!@element.dispatchEvent(event)

  forward: (name) ->
    @on name, ({detail, bubbles, cancelable, composed}) =>
      @trigger name, detail, {bubbles, cancelable, composed}

  # handles child events for delegation
  on: (name, handler) ->
    @element.shadowRoot.addEventListener(name, handler)
    @addReleaseCallback => @element.shadowRoot.removeEventListener(name, handler)

  off: (name, handler) -> @element.shadowRoot.removeEventListener(arguments...)

  listenTo: (emitter, key, fn) ->
    emitter.on key, fn
    @addReleaseCallback => emitter.off key, fn