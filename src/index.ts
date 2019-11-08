import { createElementType } from "./element";
import {
  normalizePropDefs,
  ComponentType as uComponentType,
  ConstructableComponent as uConstructableComponent,
  FunctionComponent as uFunctionComponent,
  Props as uProps,
  ComponentOptions as uComponentOptions,
  ICustomElement as uICustomElement
} from "./utils";

export type Props = uProps;
export type ComponentOptions = uComponentOptions;
export type ComponentType = uComponentType;
export type ConstructableComponent = uConstructableComponent;
export type FunctionComponent = uFunctionComponent;
export type ICustomElement = uICustomElement;
export type RegisterOptions = {
  BaseElement?: typeof HTMLElement;
  extension?: { extends: string };
};

export function register(
  tag: string,
  props: Props = {},
  options: RegisterOptions = {}
) {
  const { BaseElement = HTMLElement, extension } = options;
  return (ComponentType: ComponentType) => {
    if (!tag) throw new Error("tag is required to register a Component");
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
  };
}

export {
  nativeShadowDOM,
  isConstructor,
  isObject,
  isFunction,
  toComponentName,
  toAttribute,
  toProperty,
  connectedToDOM
} from "./utils";
export { createMixin, compose } from "./mixin";
export * from "./context";
export { getCurrentElement } from "./element";
export { hot } from "./hot";
