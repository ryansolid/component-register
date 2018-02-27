import createMixin from './create'
import Utils from '../utils'

export default createMixin (options) ->
  {element} = options
  timer = {
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
  {options..., timer}