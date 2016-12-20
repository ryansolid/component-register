var Utils, registry,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Utils = require('./utils');

module.exports = {
  Element: require('./element'),
  Component: require('./component'),
  Registry: registry = require('./registry'),
  Utils: Utils,
  registerComponent: function(component) {
    var CustomElement, element;
    Utils.normalizePropDefs(component.props);
    element = CustomElement = (function(superClass) {
      var name, prop;

      extend(CustomElement, superClass);

      function CustomElement() {
        return CustomElement.__super__.constructor.apply(this, arguments);
      }

      CustomElement.prototype.__component_type = component;

      CustomElement.observedAttributes = (function() {
        var ref, results;
        ref = component.props;
        results = [];
        for (name in ref) {
          prop = ref[name];
          results.push(prop.attribute);
        }
        return results;
      })();

      return CustomElement;

    })(component.prototype.element_type);
    registry.register(component);
    customElements.define(component.tag, element);
    return component;
  },
  create: function(tag, options) {
    var element, k, ref, ref1, ref2, v;
    element = document.createElement(tag);
    if (options.attributes) {
      ref = options.attributes;
      for (k in ref) {
        v = ref[k];
        if (!Utils.isString(v)) {
          v = JSON.stringify(v);
        }
        element.setAttribute(k, v);
      }
    }
    if (options.properties) {
      ref1 = options.properties;
      for (k in ref1) {
        v = ref1[k];
        element[k] = v;
      }
    }
    if (options.events) {
      ref2 = options.events;
      for (k in ref2) {
        v = ref2[k];
        element.addEventListener(k, v);
      }
    }
    if (options.template) {
      element.innerHTML = options.template;
    }
    if (options.context) {
      element.context = options.context;
    }
    return element;
  }
};
