var BaseElement, ComponentParser, Parser, Stringifier, Utils, ref,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Utils = require('./utils');

ComponentParser = require('./css_parser');

ref = require('shady-css-parser'), Parser = ref.Parser, Stringifier = ref.Stringifier;

module.exports = BaseElement = (function(superClass) {
  extend(BaseElement, superClass);

  function BaseElement() {
    this.boundCallback = bind(this.boundCallback, this);
    return BaseElement.__super__.constructor.apply(this, arguments);
  }

  BaseElement.prototype.boundCallback = function() {
    var base, err, error, fn, key, node, nodes, parsed, parser, prop, ref1, script, styles;
    this.props = Utils.cloneProps(this.__component_type.props);
    this.__updating = [];
    ref1 = this.props;
    fn = (function(_this) {
      return function(key, prop) {
        var attr, reflected, value;
        if (((attr = _this.getAttribute(prop.attribute)) != null) && (value = Utils.parseAttributeValue(attr))) {
          _this.props[key].value = value;
        }
        if ((value = _this[key]) != null) {
          _this.props[key].value = value;
        }
        if (reflected = Utils.reflect(_this.props[key].value)) {
          _this.setAttribute(prop.attribute, reflected);
        }
        return Object.defineProperty(_this, key, {
          get: function() {
            return this.props[key].value;
          },
          set: function(val) {
            this.__updating[key] = true;
            this.props[key].value = val;
            if (reflected = Utils.reflect(val)) {
              this.setAttribute(prop.attribute, reflected);
            }
            if (typeof this.propertyChange === "function") {
              this.propertyChange(key, val);
            }
            return delete this.__updating[key];
          }
        });
      };
    })(this);
    for (key in ref1) {
      prop = ref1[key];
      fn(key, prop);
    }
    try {
      this.__component = new this.__component_type(this, Utils.propValues(this.props));
    } catch (error) {
      err = error;
      console.error("Error creating component " + (Utils.toComponentName(this.__component_type.tag)) + ":", err);
    }
    this.propertyChange = this.__component.onPropertyChange;
    setTimeout((function(_this) {
      return function() {
        var base;
        if (_this.__released) {
          return;
        }
        return typeof (base = _this.__component).onMounted === "function" ? base.onMounted(_this) : void 0;
      };
    })(this), 0);
    this.attachShadow({
      mode: 'open'
    });
    (base = this.shadowRoot).host || (base.host = this);
    if (styles = this.__component_type.styles) {
      if (Utils.nativeShadowDOM) {
        script = document.createElement('style');
        script.textContent = styles;
        this.shadowRoot.appendChild(script);
      } else if (!document.head.querySelector('#style-' + this.__component_type.tag)) {
        parser = new Parser(new ComponentParser(this.__component_type.tag));
        parsed = parser.parse(styles);
        styles = (new Stringifier()).stringify(parsed);
        script = document.createElement('style');
        script.id = 'style-' + this.__component_type.tag;
        script.textContent = styles;
        document.head.appendChild(script);
      }
    }
    nodes = this.__component.renderTemplate(this.__component_type.template, this.__component);
    while (node = nodes[0]) {
      node.host = this;
      this.shadowRoot.appendChild(node);
    }
  };

  BaseElement.prototype.connectedCallback = function() {
    var context;
    if ((context = this.context) || (this.getAttribute('data-root') != null)) {
      this.__component_type.prototype.bindDom(this, context || {});
    }
    return delete this.context;
  };

  BaseElement.prototype.disconnectedCallback = function() {
    var node, ref1, ref2, ref3;
    while (node = (ref2 = this.shadowRoot) != null ? ref2.firstChild : void 0) {
      if ((ref1 = this.__component) != null) {
        ref1.unbindDom(node);
      }
      this.shadowRoot.removeChild(node);
    }
    if ((ref3 = this.__component) != null) {
      if (typeof ref3.onRelease === "function") {
        ref3.onRelease(this);
      }
    }
    delete this.__component;
    return this.__released = true;
  };

  BaseElement.prototype.attributeChangedCallback = function(name, old_val, new_val) {
    if (!this.props) {
      return;
    }
    name = this.lookupProp(name);
    if (this.__updating[name]) {
      return;
    }
    if (name in this.props) {
      return this[name] = Utils.parseAttributeValue(new_val);
    }
  };

  BaseElement.prototype.lookupProp = function(attr_name) {
    var k, props, v;
    if (!(props = this.__component_type.props)) {
      return;
    }
    for (k in props) {
      v = props[k];
      if (v.attribute === attr_name) {
        return k;
      }
    }
  };

  BaseElement.prototype.createEvent = function(name, params) {
    var event;
    event = document.createEvent('CustomEvent');
    event.initCustomEvent(name, params.bubbles, params.cancelable, params.detail);
    return event;
  };

  return BaseElement;

})(HTMLElement);
