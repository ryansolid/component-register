mixin = (element) ->
  events = {
    trigger: (name, options={}) -> element.trigger(options)

    forward: (name) ->
      events.on name, ({detail, bubbles, cancelable, composed}) =>
        events.trigger name, detail, {bubbles, cancelable, composed}

    # handles child events for delegation
    on: (name, handler) ->
      element.shadowRoot.addEventListener(name, handler)
      element.addReleaseCallback => element.shadowRoot.removeEventListener(name, handler)

    off: (name, handler) -> element.shadowRoot.removeEventListener(arguments...)

    listenTo: (emitter, key, fn) ->
      emitter.on key, fn
      element.addReleaseCallback => emitter.off key, fn
  }

export default (Component) ->
  (element, props) ->
    newProps = Object.assign(props, { events: mixin(element) })
    return new Component(element, newProps) if Component::constructor.name
    Component(element, newProps)