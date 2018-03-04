import Utils from './utils'
import createElementDefinition from './element'
import createMixin from './mixins/create'

register = (tag, { props, BaseElement = HTMLElement } = {}, extension) -> (ComponentType) ->
  return console.error 'Component missing static tag property' unless tag
  Utils.normalizePropDefs(props)
  element = createElementDefinition({
    BaseElement, ComponentType, propDefinition: props
  })
  customElements.define(tag, element, extension)
  element

export { Utils, register, createMixin }