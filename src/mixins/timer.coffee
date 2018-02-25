mixin = (element) ->
  {
    delay: (delayTime, callback) ->
      [delayTime, callback] = [0, delayTime] if Utils.isFunction(delayTime)
      timer = setTimeout(callback, delayTime)
      element.addReleaseCallback -> clearTimeout(timer)
      return timer

    interval: (delayTime, callback) ->
      timer = setInterval(callback, delayTime)
      element.addReleaseCallback -> clearInterval(timer)
      return timer
  }

export default (Component) ->
  (element, props) ->
    newProps = Object.assign(props, { timer: mixin(element) })
    return new Component(element, newProps) if Component::constructor.name
    Component(element, newProps)