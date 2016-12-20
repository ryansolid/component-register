var ComponentUtils, div, shadowDOMV1, v1;

div = document.createElement('div');

shadowDOMV1 = !!div.attachShadow;


/* force polyfill until browsers are consistent */

v1 = require('skatejs-named-slots').v1;

if (shadowDOMV1) {
  v1();
}

require('document-register-element');

module.exports = ComponentUtils = (function() {
  function ComponentUtils() {}

  ComponentUtils.nativeShadowDOM = false;

  ComponentUtils.normalizePropDefs = function(props) {
    var base, base1, base2, k, v;
    if (!props) {
      return;
    }
    for (k in props) {
      v = props[k];
      if (!(ComponentUtils.isObject(v) && 'value' in v)) {
        props[k] = {
          value: v
        };
      }
      if ((base = props[k]).notify == null) {
        base.notify = false;
      }
      (base1 = props[k]).event_name || (base1.event_name = ComponentUtils.toEventName(k));
      (base2 = props[k]).attribute || (base2.attribute = ComponentUtils.toAttribute(k));
    }
  };

  ComponentUtils.cloneProps = function(props) {
    var k, new_props, prop;
    new_props = {};
    for (k in props) {
      prop = props[k];
      new_props[k] = ComponentUtils.shallowClone(prop);
      if (ComponentUtils.isObject(prop.value) && !ComponentUtils.isFunction(prop.value)) {
        new_props[k].value = ComponentUtils.shallowClone(prop.value);
      }
    }
    return new_props;
  };

  ComponentUtils.propValues = function(props) {
    var k, prop, values;
    values = {};
    for (k in props) {
      prop = props[k];
      values[k] = prop.value;
    }
    return values;
  };

  ComponentUtils.toAttribute = function(prop_name) {
    return prop_name.replace(/_/g, '-').toLowerCase();
  };

  ComponentUtils.toEventName = function(prop_name) {
    return prop_name.replace(/_/g, '').toLowerCase();
  };

  ComponentUtils.toComponentName = function(tag) {
    return tag != null ? tag.toLowerCase().replace(/(^|-)([a-z])/g, function(test) {
      return test.toUpperCase().replace('-', '');
    }) : void 0;
  };

  ComponentUtils.parseAttributeValue = function(value) {
    var err, error, parsed;
    if (!value) {
      return;
    }
    try {
      parsed = JSON.parse(value);
    } catch (error) {
      err = error;
      parsed = value;
    }
    if (typeof parsed !== 'string') {
      return parsed;
    }
    if (/^[0-9]*$/.test(parsed)) {
      return +parsed;
    }
    return parsed;
  };

  ComponentUtils.reflect = function(value) {
    var reflect;
    if (!(!ComponentUtils.isObject(value) && (reflect = value != null ? typeof value.toString === "function" ? value.toString() : void 0 : void 0))) {
      return;
    }
    return reflect;
  };

  ComponentUtils.isObject = function(obj) {
    var ref;
    return obj !== null && ((ref = typeof obj) === 'object' || ref === 'function');
  };

  ComponentUtils.isFunction = function(val) {
    return Object.prototype.toString.call(val) === "[object Function]";
  };

  ComponentUtils.isString = function(val) {
    return Object.prototype.toString.call(val) === "[object String]";
  };

  ComponentUtils.shallowClone = function(old_obj) {
    var i, new_obj;
    new_obj = {};
    for (i in old_obj) {
      if (old_obj.hasOwnProperty(i)) {
        new_obj[i] = old_obj[i];
      }
    }
    return new_obj;
  };

  return ComponentUtils;

})();
