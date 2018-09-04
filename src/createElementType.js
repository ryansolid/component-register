import { connectedToDOM, propValues, isConstructor, toComponentName, reflect, initializeProps, parseAttributeValue } from './utils';


export default function createElementType({BaseElement, propDefinition, ComponentType}) {
  const propKeys = Object.keys(propDefinition);
  return class CustomElement extends BaseElement {
    static get observedAttributes() { return propKeys.map(k => propDefinition[k].attribute); }

    connectedCallback() {
      // check that infact it connected since polyfill sometimes double calls
      if (!connectedToDOM(this) || this.__initialized) return;
      this.__releaseCallbacks = [];
      this.__propertyChangedCallbacks = [];
      this.__updating = {};
      this.props = initializeProps(this, propDefinition);
      const props = propValues(this.props)
      try {
        if (isConstructor(ComponentType)) new ComponentType({element: this, props});
        else ComponentType({element: this, props});
      } catch (err) {
        console.error(`Error creating component ${toComponentName(this.nodeName.toLowerCase())}:`, err);
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

    lookupProp(attrName) {
      if(!propDefinition) return;
      return propKeys.find(k => attrName === k || attrName === propDefinition[k].attribute);
    }

    renderRoot() { return this.shadowRoot || this.attachShadow({ mode: 'open' }); }

    setProperty(name, value) {
      if (!(name in this.props)) return;
      const prop = this.props[name],
        oldValue = prop.value;
      prop.value = value;
      reflect(this, prop.attribute, value);
      if (prop.notify)
        this.trigger('propertychange', {detail: {value, oldValue, name}})
    }

    trigger(name, {detail, bubbles = true, cancelable = true, composed = false}) {
      const event = new CustomEvent(name, {detail, bubbles, cancelable, composed});
      let notCancelled = true;
      if (this['on'+name]) notCancelled = !!this['on'+name](event);
      notCancelled && !!this.dispatchEvent(event);
    }

    addReleaseCallback(fn) { this.__releaseCallbacks.push(fn) }

    addPropertyChangedCallback(fn) { this.__propertyChangedCallbacks.push(fn); }
  }
}