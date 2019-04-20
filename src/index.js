import { createElementType } from './element';
import { normalizePropDefs } from './utils';

export function register(tag, props = {}, options = {}) {
  const { BaseElement = HTMLElement, extension } = options;
  return ComponentType => {
    if (!tag) throw new Error('tag is required to register a Component');
    let ElementType = customElements.get(tag);
    if (ElementType) {
      // Consider disabling this in a production mode
      ElementType.Component = ComponentType;
      return ElementType;
    }

    ElementType = createElementType(BaseElement, normalizePropDefs(props));
    ElementType.Component = ComponentType;
    customElements.define(tag, ElementType, extension);
    return ElementType;
  }
}

export { nativeShadowDOM, isConstructor, isObject, isFunction, toComponentName, toAttribute, toProperty, connectedToDOM } from './utils';
export { createMixin, compose } from './mixin';
export * from './context';
export { getCurrentElement } from './element';
export { hot } from './hot';