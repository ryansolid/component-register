import { createElementType } from './element';
import { normalizePropDefs } from './utils';

export function register(tag, props = {}, options = {}) {
  const { BaseElement = HTMLElement, extension } = options;
  return ComponentType => {
    if (!tag) throw new Error('tag is required to register a Component');
    if (customElements.get(tag)) {
      console.log('Component already registered with tag', tag);
      return customElements.get(tag);
    }

    const element = createElementType({
      BaseElement, ComponentType, propDefinition: normalizePropDefs(props)
    });
    customElements.define(tag, element, extension);
    return element;
  }
}

export { nativeShadowDOM, isConstructor, isObject, isFunction, toComponentName, toAttribute, toProperty, connectedToDOM } from './utils';
export { createMixin, compose } from './mixin';
export * from './context';
export { getCurrentElement } from './element';