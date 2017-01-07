###
# Object.assign
###
if typeof Object.assign != 'function'
  Object.assign = (target) ->
    'use strict'
    # We must check against these specific cases.
    if target == undefined or target == null
      throw new TypeError('Cannot convert undefined or null to object')
    output = Object(target)
    index = 1
    while index < arguments.length
      source = arguments[index]
      if source != undefined and source != null
        for nextKey of source
          if source.hasOwnProperty(nextKey)
            output[nextKey] = source[nextKey]
      index++
    output

###
# Array.find
###
if !Array::find
  Object.defineProperty Array.prototype, 'find', value: (predicate) ->
    if @ is null
      throw new TypeError('"this" is null or not defined')
    o = Object(@)
    len = o.length >>> 0
    if typeof predicate isnt 'function'
      throw new TypeError('predicate must be a function')
    thisArg = arguments[1]
    return v for k, v of o when predicate.call(thisArg, v, k, o)
    undefined