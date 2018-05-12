import Utils from './utils'
import createElementDefinition from './element'

register = (tag, { props, BaseElement = HTMLElement } = {}, extension) -> (ComponentType) ->
  return console.error 'Component missing static tag property' unless tag
  Utils.normalizePropDefs(props)
  element = createElementDefinition({
    BaseElement, ComponentType, propDefinition: props
  })
  customElements.define(tag, element, extension)
  element

compose = (...fns) ->
  return ((x) => x) if fns.length is 0
  return fns[0] if fns.length is 1
  fns.reduce((a, b) => (...args) => a(b(...args)))

export { Utils, register, compose }
export { default as createMixin } from './createMixin'