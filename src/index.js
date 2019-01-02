import { createElementType } from './element';
import { normalizePropDefs } from './utils';

export function register(tag, props = {}, options = {}) {
  const { BaseElement = HTMLElement, extension } = options;
  return ComponentType => {
    if (!tag) throw new Error('Component missing tag property');
    if (customElements.get(tag)) return console.log('Component already registered with tag', tag);

    const element = createElementType({
      BaseElement, ComponentType, propDefinition: normalizePropDefs(props)
    });
    customElements.define(tag, element, extension);
    return element;
  }
}

export { nativeShadowDOM, isConstructor, isObject, isFunction, isString, toComponentName, toAttribute, toProperty, connectedToDOM } from './utils';
export { createMixin, compose } from './mixin';
export * from './context';
export { getCurrentElement } from './element';