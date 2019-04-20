const testElem = document.createElement('div');

function cloneProps(props) {
  const propKeys = Object.keys(props);
  return propKeys.reduce((memo, k) => {
    const prop = props[k];
    memo[k] = { ...prop };
    if (isObject(prop.value) && !isFunction(prop.value) && !Array.isArray(prop.value)) memo[k].value = { ...prop.value };
    if (Array.isArray(prop.value)) memo[k].value = prop.value.slice(0);
    return memo;
  }, {});
}

export const nativeShadowDOM = !!testElem.attachShadow;

export function normalizePropDefs(props) {
  if (!props) return;
  const propKeys = Object.keys(props);
  return propKeys.reduce((memo, k) => {
    const v = props[k];
    memo[k] = !(isObject(v) && 'value' in v) ? { value: v } : v;
    memo[k].notify != null || (memo[k].notify = false);
    memo[k].attribute || (memo[k].attribute = toAttribute(k));
    return memo;
  }, {});
}

export function propValues(props) {
  const propKeys = Object.keys(props);
  return propKeys.reduce((memo, k) => {
    memo[k] = props[k].value
    return memo
  }, {});
}

export function initializeProps(element, propDefinition) {
  const props = cloneProps(propDefinition),
    propKeys = Object.keys(propDefinition);
  propKeys.forEach(key => {
    const prop = props[key],
      attr = element.getAttribute(prop.attribute),
      value = element[key];
    if (attr) prop.value = parseAttributeValue(attr)
    if (value != null) prop.value = Array.isArray(value) ? value.slice(0) : value;
    reflect(element, prop.attribute, prop.value);
    Object.defineProperty(element, key, {
      get() { return prop.value; },
      set(val) {
        const oldValue = prop.value;
        prop.value = val;
        reflect(this, prop.attribute, prop.value);
        for (let i = 0, l = this.__propertyChangedCallbacks.length; i < l; i++ ) {
          this.__propertyChangedCallbacks[i](key, val, oldValue)
        }
      },
      enumerable: true,
      configurable: true
    });
  });
  return props;
}

export function parseAttributeValue(value) {
  if (!value) return;
  let parsed;
  try {
    parsed = JSON.parse(value);
  }
  catch(err) {
    parsed = value;
  }
  if (!(typeof parsed === 'string')) return parsed;
  if (/^[0-9]*$/.test(parsed)) return +parsed;
  return parsed;
}

export function reflect(node, attribute, value) {
  if(isObject(value)) return;

  let reflect = value ? (typeof value.toString === 'function' ? value.toString() : undefined) : undefined;
  if (reflect && reflect !== 'false') {
    node.__updating[attribute] = true;
    if (reflect === 'true') reflect = '';
    node.setAttribute(attribute, reflect);
    Promise.resolve().then(() => delete node.__updating[attribute])
  } else node.removeAttribute(attribute);
}

export function toAttribute(propName) { return propName.replace(/\.?([A-Z]+)/g, (x, y) =>  "-" + y.toLowerCase()).replace('_','-').replace(/^-/, ""); }

export function toProperty(attr) { return attr.toLowerCase().replace(/(-)([a-z])/g, test => test.toUpperCase().replace('-','')); }

export function toComponentName(tag) { return tag.toLowerCase().replace(/(^|-)([a-z])/g, test => test.toUpperCase().replace('-','')); }

export function isObject(obj) { return obj != null && (typeof obj === 'object' || typeof obj === 'function'); }

export function isFunction(val) { return Object.prototype.toString.call(val) === "[object Function]" }

export function isConstructor(f) {
  return typeof f === 'function' && f.toString().indexOf('class') === 0
}

export function connectedToDOM(node) {
  if ('isConnected' in node) return node.isConnected;
  const doc = node.ownerDocument;
  if (doc.body.contains(node)) return true;
  while (node && node !== doc.documentElement) {
    node = node.parentNode || node.host;
  }
  return node === doc.documentElement;
}
