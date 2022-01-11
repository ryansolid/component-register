import {
  propValues,
  isConstructor,
  initializeProps,
  parseAttributeValue,
  ICustomElement,
  ConstructableComponent,
  FunctionComponent,
  PropsDefinition,
} from "./utils";

let currentElement: HTMLElement & ICustomElement;
export function getCurrentElement() {
  return currentElement;
}

export function noShadowDOM() {
  Object.defineProperty(currentElement, "renderRoot", {
    value: currentElement,
  });
}

export function createElementType<T>(
  BaseElement: typeof HTMLElement,
  propDefinition: PropsDefinition<T>
) {
  const propKeys = Object.keys(propDefinition) as Array<
    keyof PropsDefinition<T>
  >;
  return class CustomElement extends BaseElement implements ICustomElement {
    [prop: string]: any;
    __initialized?: boolean;
    __released: boolean;
    __releaseCallbacks: any[];
    __propertyChangedCallbacks: any[];
    __updating: { [prop: string]: any };
    props: { [prop: string]: any };

    static get observedAttributes() {
      return propKeys.map((k) => propDefinition[k].attribute);
    }

    constructor() {
      super();
      this.__initialized = false;
      this.__released = false;
      this.__releaseCallbacks = [];
      this.__propertyChangedCallbacks = [];
      this.__updating = {};
      this.props = {};
    }

    connectedCallback() {
      if (this.__initialized) return;
      this.__releaseCallbacks = [];
      this.__propertyChangedCallbacks = [];
      this.__updating = {};
      this.props = initializeProps(this as any, propDefinition);
      const props = propValues<T>(this.props as PropsDefinition<T>),
        ComponentType = this.Component as
          | Function
          | { new (...args: any[]): any },
        outerElement = currentElement;
      try {
        currentElement = this;
        this.__initialized = true;
        if (isConstructor(ComponentType))
          new (ComponentType as ConstructableComponent<T>)(props, {
            element: this as ICustomElement,
          });
        else
          (ComponentType as FunctionComponent<T>)(props, {
            element: this as ICustomElement,
          });
      } finally {
        currentElement = outerElement;
      }
    }

    async disconnectedCallback() {
      // prevent premature releasing when element is only temporarely removed from DOM
      await Promise.resolve();
      if (this.isConnected) return;
      this.__propertyChangedCallbacks.length = 0;
      let callback = null;
      while ((callback = this.__releaseCallbacks.pop())) callback(this);
      delete this.__initialized;
      this.__released = true;
    }

    attributeChangedCallback(name: string, oldVal: string, newVal: string) {
      if (!this.__initialized) return;
      if (this.__updating[name]) return;
      name = this.lookupProp(name)!;
      if (name in propDefinition) {
        if (newVal == null && !this[name]) return;
        this[name] = propDefinition[name as keyof T].parse
          ? parseAttributeValue(newVal)
          : newVal;
      }
    }

    lookupProp(attrName: string) {
      if (!propDefinition) return;
      return propKeys.find(
        (k) => attrName === k || attrName === propDefinition[k].attribute
      ) as string | undefined;
    }

    get renderRoot() {
      return this.shadowRoot || this.attachShadow({ mode: "open" });
    }

    addReleaseCallback(fn: () => void) {
      this.__releaseCallbacks.push(fn);
    }

    addPropertyChangedCallback(fn: (name: string, value: any) => void) {
      this.__propertyChangedCallbacks.push(fn);
    }
  };
}
