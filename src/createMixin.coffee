export default (mixinFn) ->
  (ComponentType) ->
    (options) ->
      options = mixinFn(options)
      return new ComponentType(options) if ComponentType::constructor.name
      ComponentType(options)
