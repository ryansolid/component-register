import { connectedToDOM, propValues, isConstructor, toComponentName, initializeProps, parseAttributeValue } from './utils';

let currentElement;
export function getCurrentElement() { return currentElement; }

export function createElementType(BaseElement, propDefinition) {
  const propKeys = Object.keys(propDefinition);
  return class CustomElement extends BaseElement {
    static get observedAttributes() { return propKeys.map(k => propDefinition[k].attribute); }

    connectedCallback() {
      // check that infact it connected since polyfill sometimes double calls
      if (!connectedToDOM(this) || this.__initializing || this.__initialized) return;
      this.__releaseCallbacks = [];
      this.__propertyChangedCallbacks = [];
      this.__updating = {};
      this.props = initializeProps(this, propDefinition);
      const props = propValues(this.props),
        ComponentType = CustomElement.Component,
        outerElement = currentElement;
      try {
        this.__initializing = true;
        currentElement = this;
        if (isConstructor(ComponentType)) new ComponentType(props, {element: this});
        else ComponentType(props, {element: this});
      } catch (err) {
        console.error(`Error creating component ${toComponentName(this.nodeName.toLowerCase())}:`, err);
      } finally {
        currentElement = outerElement;
        delete this.__initializing;
      }
      this.__initialized = true;
    }

    async disconnectedCallback() {
      // prevent premature releasing when element is only temporarely removed from DOM
      await Promise.resolve()
      if (connectedToDOM(this)) return;
      this.__propertyChangedCallbacks.length = 0
      let callback = null;
      while(callback = this.__releaseCallbacks.pop()) callback(this);
      delete this.__initialized;
      this.__released = true;
    }

    attributeChangedCallback(name, oldVal, newVal) {
      if (!this.__initialized) return;
      if (this.__updating[name]) return;
      name = this.lookupProp(name);
      if (name in propDefinition) {
        if (newVal == null && !this[name]) return;
        this[name] = parseAttributeValue(newVal);
      }
    }

    reloadComponent() {
      let callback = null;
      while(callback = this.__releaseCallbacks.pop()) callback(this);
      delete this.__initialized;
      this.renderRoot().textContent = '';
      this.connectedCallback();
    }

    lookupProp(attrName) {
      if(!propDefinition) return;
      return propKeys.find(k => attrName === k || attrName === propDefinition[k].attribute);
    }

    renderRoot() { return this.shadowRoot || this.attachShadow({ mode: 'open' }); }

    setProperty(name, value) {
      if (!(name in this.props)) return;
      const prop = this.props[name],
        oldValue = prop.value;
      this[name] = value;
      if (prop.notify)
        this.trigger('propertychange', {detail: {value, oldValue, name}})
    }

    trigger(name, {detail, bubbles = true, cancelable = true, composed = true} = {}) {
      const event = new CustomEvent(name, {detail, bubbles, cancelable, composed});
      let cancelled = false;
      if (this['on'+name]) cancelled = this['on'+name](event) === false;
      if (cancelled) event.preventDefault();
      this.dispatchEvent(event);
      return event;
    }

    addReleaseCallback(fn) { this.__releaseCallbacks.push(fn) }

    addPropertyChangedCallback(fn) { this.__propertyChangedCallbacks.push(fn); }
  }
}