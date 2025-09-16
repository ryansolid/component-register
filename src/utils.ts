export interface PropDefinition<T> {
  value: T;
  attribute: string;
  notify: boolean;
  reflect: boolean;
  parse?: boolean;
}
export interface ICustomElement {
  [prop: string]: any;
  __initialized?: boolean;
  __released: boolean;
  __releaseCallbacks: any[];
  __propertyChangedCallbacks: any[];
  __updating: { [prop: string]: any };
  props: { [prop: string]: any };
  lookupProp(attrName: string): string | undefined;
  renderRoot: Element | Document | ShadowRoot | DocumentFragment;
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
      memo[k].value = prop.value.slice(0) as unknown as T[keyof T];
    return memo;
  }, {} as PropsDefinition<T>);
}

export function normalizePropDefs<T>(
  props: PropsDefinitionInput<T>
): PropsDefinition<T> {
  if (!props) return {} as PropsDefinition<T>;
  const propKeys = Object.keys(props) as Array<keyof PropsDefinition<T>>;
  return propKeys.reduce((memo, k) => {
    const v = props[k];
    memo[k] = !(isObject(v) && "value" in (v as object))
      ? ({ value: v } as unknown as PropDefinition<T[keyof T]>)
      : (v as PropDefinition<T[keyof T]>);
    memo[k].attribute || (memo[k].attribute = (k as string));
    memo[k].parse =
      "parse" in memo[k] ? memo[k].parse : typeof memo[k].value !== "string";
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
  propKeys.forEach((key) => {
    const prop = props[key],
      attr = element.getAttribute(prop.attribute),
      value = element[key];
    if (attr != null) prop.value = prop.parse ? parseAttributeValue(attr) : attr;
    if (value != null)
      prop.value = Array.isArray(value) ? value.slice(0) : value;
    prop.reflect && reflect(element, prop.attribute, prop.value, !!prop.parse);
    Object.defineProperty(element, key, {
      get() {
        return prop.value;
      },
      set(val) {
        const oldValue = prop.value;
        prop.value = val;
        prop.reflect && reflect(this, prop.attribute, prop.value, !!prop.parse);
        for (
          let i = 0, l = this.__propertyChangedCallbacks.length;
          i < l;
          i++
        ) {
          this.__propertyChangedCallbacks[i](key, val, oldValue);
        }
      },
      enumerable: true,
      configurable: true,
    });
  });
  return props;
}

export function parseAttributeValue(value: string) {
  if (!value) return;
  try {
    return JSON.parse(value);
  } catch (err) {
    return value;
  }
}

export function reflect<T>(
  node: UpdateableElement<T>,
  attribute: string,
  value: any,
  parse: boolean
) {
  if (value == null || value === false) return node.removeAttribute(attribute);
  let reflect = parse ? JSON.stringify(value) : value;
  node.__updating[attribute] = true;
  if (reflect === "true") reflect = "";
  node.setAttribute(attribute, reflect);
  Promise.resolve().then(() => delete node.__updating[attribute]);
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

export function reloadElement(node: ICustomElement) {
  let callback = null;
  while ((callback = node.__releaseCallbacks.pop())) callback(node);
  delete node.__initialized;
  node.renderRoot.textContent = "";
  node.connectedCallback();
}
