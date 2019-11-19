interface PropDefinition<T> {
  value: T;
  attribute: string;
  notify: boolean;
}
export interface ICustomElement {
  [prop: string]: any;
  __initializing: boolean;
  __initialized: boolean;
  __released: boolean;
  __releaseCallbacks: any[];
  __propertyChangedCallbacks: any[];
  __updating: { [prop: string]: any };
  props: { [prop: string]: any };
  reloadComponent(): void;
  lookupProp(attrName: string): string | undefined;
  renderRoot(): Element | Document | ShadowRoot | DocumentFragment;
  setProperty(name: string, value: unknown): void;
  trigger(
    name: string,
    options: {
      detail?: any;
      bubbles?: boolean;
      cancelable?: boolean;
      composed?: boolean;
    }
  ): CustomEvent;
  addReleaseCallback(fn: () => void): void;
  addPropertyChangedCallback(fn: (name: string, value: any) => void): void;
}
export type UpdateableElement<T> = HTMLElement & ICustomElement & T;
export interface ComponentOptions {
  element: ICustomElement;
}
export interface ConstructableComponent<T> {
  new (props: T, options: ComponentOptions): unknown;
}
export interface FunctionComponent<T> {
  (props: T, options: ComponentOptions): unknown;
}
export type PropsDefinitionInput<T> = {
  [P in keyof T]: PropDefinition<T[P]> | T[P];
};
export type PropsDefinition<T> = {
  [P in keyof T]: PropDefinition<T[P]>;
};
export type ComponentType<T> = FunctionComponent<T> | ConstructableComponent<T>;

const testElem = document.createElement("div");

function cloneProps<T>(props: PropsDefinition<T>) {
  const propKeys = Object.keys(props) as Array<keyof PropsDefinition<T>>;
  return propKeys.reduce((memo, k) => {
    const prop = props[k];
    memo[k] = Object.assign({}, prop);
    if (
      isObject(prop.value) &&
      !isFunction(prop.value) &&
      !Array.isArray(prop.value)
    )
      memo[k].value = Object.assign({}, prop.value);
    if (Array.isArray(prop.value))
      memo[k].value = (prop.value.slice(0) as unknown) as T[keyof T];
    return memo;
  }, {} as PropsDefinition<T>);
}

export const nativeShadowDOM = !!testElem.attachShadow;

export function normalizePropDefs<T>(
  props: PropsDefinitionInput<T>
): PropsDefinition<T> {
  if (!props) return {} as PropsDefinition<T>;
  const propKeys = Object.keys(props) as Array<keyof PropsDefinition<T>>;
  return propKeys.reduce((memo, k) => {
    const v = props[k];
    memo[k] = !(isObject(v) && "value" in v)
      ? (({ value: v } as unknown) as PropDefinition<T[keyof T]>)
      : (v as PropDefinition<T[keyof T]>);
    memo[k].notify != null || (memo[k].notify = false);
    memo[k].attribute || (memo[k].attribute = toAttribute(k as string));
    return memo;
  }, {} as PropsDefinition<T>);
}

export function propValues<T>(props: PropsDefinition<T>) {
  const propKeys = Object.keys(props) as Array<keyof PropsDefinition<T>>;
  return propKeys.reduce((memo, k) => {
    memo[k] = props[k].value;
    return memo;
  }, {} as T);
}

export function initializeProps<T>(
  element: UpdateableElement<T>,
  propDefinition: PropsDefinition<T>
) {
  const props = cloneProps(propDefinition),
    propKeys = Object.keys(propDefinition) as Array<keyof PropsDefinition<T>>;
  propKeys.forEach(key => {
    const prop = props[key],
      attr = element.getAttribute(prop.attribute),
      value = element[key];
    if (attr) prop.value = parseAttributeValue(attr);
    if (value != null)
      prop.value = Array.isArray(value) ? value.slice(0) : value;
    reflect(element, prop.attribute, prop.value);
    Object.defineProperty(element, key, {
      get() {
        return prop.value;
      },
      set(val) {
        const oldValue = prop.value;
        prop.value = val;
        reflect(this, prop.attribute, prop.value);
        for (
          let i = 0, l = this.__propertyChangedCallbacks.length;
          i < l;
          i++
        ) {
          this.__propertyChangedCallbacks[i](key, val, oldValue);
        }
      },
      enumerable: true,
      configurable: true
    });
  });
  return props;
}

export function parseAttributeValue(value: string) {
  if (!value) return;
  let parsed;
  try {
    parsed = JSON.parse(value);
  } catch (err) {
    parsed = value;
  }
  if (!(typeof parsed === "string")) return parsed;
  if (/^[0-9]*$/.test(parsed)) return +parsed;
  return parsed;
}

export function reflect<T>(
  node: UpdateableElement<T>,
  attribute: string,
  value: any
) {
  if (isObject(value)) return;

  let reflect = value
    ? typeof value.toString === "function"
      ? value.toString()
      : undefined
    : undefined;
  if (reflect && reflect !== "false") {
    node.__updating[attribute] = true;
    if (reflect === "true") reflect = "";
    node.setAttribute(attribute, reflect);
    Promise.resolve().then(() => delete node.__updating[attribute]);
  } else node.removeAttribute(attribute);
}

export function toAttribute(propName: string) {
  return propName
    .replace(/\.?([A-Z]+)/g, (x, y) => "-" + y.toLowerCase())
    .replace("_", "-")
    .replace(/^-/, "");
}

export function toProperty(attr: string) {
  return attr
    .toLowerCase()
    .replace(/(-)([a-z])/g, test => test.toUpperCase().replace("-", ""));
}

export function toComponentName(tag: string) {
  return tag
    .toLowerCase()
    .replace(/(^|-)([a-z])/g, test => test.toUpperCase().replace("-", ""));
}

export function isObject(obj: any) {
  return obj != null && (typeof obj === "object" || typeof obj === "function");
}

export function isFunction(val: any) {
  return Object.prototype.toString.call(val) === "[object Function]";
}

export function isConstructor(f: Function) {
  return typeof f === "function" && f.toString().indexOf("class") === 0;
}

export function connectedToDOM(node: Node) {
  if ("isConnected" in node) return node.isConnected;
  const doc = (node as Node).ownerDocument;
  if (!doc) return false;
  if (doc.body.contains(node)) return true;
  while (node && node !== doc.documentElement) {
    node = node.parentNode || (node as ShadowRoot).host;
  }
  return node === doc.documentElement;
}
