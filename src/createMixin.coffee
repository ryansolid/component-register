import Utils from './utils'

export default (mixinFn) ->
  (ComponentType) ->
    (options) ->
      options = mixinFn(options)
      return new ComponentType(options) if Utils.isConstructor(ComponentType)
      ComponentType(options)
