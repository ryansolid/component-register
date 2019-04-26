import { createElementType, ICustomElement } from './element';
import { normalizePropDefs, ComponentType, ConstructableComponent, FunctionComponent, Props } from './utils';

export type Props = Props;
export type ComponentType = ComponentType;
export type ConstructableComponent = ConstructableComponent;
export type FunctionComponent = FunctionComponent;
export type ICustomElement = ICustomElement;
export type RegisterOptions = {
  BaseElement?: typeof HTMLElement,
  extension?: { extends: string }
}

export function register(tag: string, props: Props = {}, options: RegisterOptions = {}) {
  const { BaseElement = HTMLElement, extension } = options;
  return (ComponentType: ComponentType) => {
    if (!tag) throw new Error('tag is required to register a Component');
    let ElementType = customElements.get(tag);
    if (ElementType) {
      // Consider disabling this in a production mode
      ElementType.prototype.Component = ComponentType;
      return ElementType;
    }

    ElementType = createElementType(BaseElement, normalizePropDefs(props));
    ElementType.prototype.Component = ComponentType;
    ElementType.prototype.registeredTag = tag;
    customElements.define(tag, ElementType, extension);
    return ElementType;
  }
}

export { nativeShadowDOM, isConstructor, isObject, isFunction, toComponentName, toAttribute, toProperty, connectedToDOM } from './utils';
export { createMixin, compose } from './mixin';
export * from './context';
export { getCurrentElement } from './element';
export { hot } from './hot';