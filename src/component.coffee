Utils = require './utils'

module.exports = class Component
  element_type: require './element'
  scope_css: true
  constructor: (@element, props) ->
    @__release_callbacks = []

  setProperty: (name, val) ->
    return unless name of @element.props
    prop = @element.props[name]
    return if prop.value is val and not Array.isArray(val)
    old_value = prop.value
    prop.value = val
    Utils.reflect(@element, prop.attribute, val)
    if prop.notify
      @trigger('propertychange', {value: val, old_value, name})

  onRender: ->
  onMounted: ->
  onPropertyChange: (name, val) ->
  onRelease: ->
    return if @__released
    @__released = true
    callback(@) while callback = @__release_callbacks.pop()
    delete @element

  wasReleased: -> !!@__released

  addReleaseCallback: (fn) -> @__release_callbacks.push(fn)

  ###############
  # Integration Methods
  # Here to make sure asyncronous operations only last the lifetime of the component
  delay: (delay_time, callback) ->
    [delay_time, callback] = [0, delay_time] if Utils.isFunction(delay_time)
    timer = setTimeout callback, delay_time
    @addReleaseCallback -> clearTimeout(timer)
    return timer

  interval: (delay_time, callback) ->
    timer = setInterval callback, delay_time
    @addReleaseCallback -> clearInterval(timer)
    return timer

  trigger: (name, detail) ->
    event = new CustomEvent(name, {detail, bubbles: true, cancelable: true})
    not_cancelled = true
    not_cancelled = !!@element['on'+name]?(event) if @element['on'+name]
    not_cancelled and !!@element.dispatchEvent(event)

  on: (name, handler) ->
    @element.addEventListener(name, handler)
    @addReleaseCallback => @element.removeEventListener(name, handler)

  off: (name, handler) -> @element.removeEventListener(arguments...)

  listenTo: (emitter, key, fn) ->
    emitter.on key, fn
    @addReleaseCallback => emitter.off key, fn