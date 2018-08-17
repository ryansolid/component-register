import createElementType from './createElementType';
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

export function compose(...fns) {
  if (fns.length === 0) return i => i;
  if (fns.length === 1) return fns[0];
  return fns.reduce((a, b) => (...args) => a(b(...args)));
}

export { nativeShadowDOM, isConstructor, isObject, isFunction, isString, toComponentName, toAttribute, toProperty, connectedToDOM } from './utils';
export { createMixin } from './createMixin';