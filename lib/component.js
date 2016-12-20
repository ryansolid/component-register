var Component, Utils,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Utils = require('./utils');

module.exports = Component = (function() {
  Component.prototype.element_type = require('./element');

  function Component(element, props) {
    this.listenTo = bind(this.listenTo, this);
    this.on = bind(this.on, this);
    this.trigger = bind(this.trigger, this);
    this.delay = bind(this.delay, this);
    this.renderTemplate = bind(this.renderTemplate, this);
    this.addReleaseCallback = bind(this.addReleaseCallback, this);
    this.onRelease = bind(this.onRelease, this);
    this.setProperty = bind(this.setProperty, this);
    this.__element = element;
    this.__release_callbacks = [];
  }

  Component.prototype.bindDom = function(node, context) {};

  Component.prototype.unbindDom = function(node) {};

  Component.prototype.setProperty = function(name, val) {
    var prop, reflected;
    if (!(name in this.__element.props)) {
      return;
    }
    prop = this.__element.props[name];
    if (prop.value === val && !Array.isArray(val)) {
      return;
    }
    prop.value = val;
    if (reflected = Utils.reflect(val)) {
      this.__element.__updating[name] = true;
      this.__element.setAttribute(prop.attribute, reflected);
      delete this.__element.__updating[name];
    }
    if (prop.notify) {
      return this.trigger(prop.event_name, val);
    }
  };

  Component.prototype.onPropertyChange = function(name, val) {};

  Component.prototype.onMounted = function() {};

  Component.prototype.onRelease = function() {
    var callback;
    if (this.__released) {
      return;
    }
    this.__released = true;
    while (callback = this.__release_callbacks.pop()) {
      callback(this);
    }
    return delete this.__element;
  };

  Component.prototype.addReleaseCallback = function(fn) {
    return this.__release_callbacks.push(fn);
  };

  Component.prototype.renderTemplate = function(template, context) {
    var el;
    if (context == null) {
      context = {};
    }
    el = document.createElement('div');
    el.innerHTML = template;
    this.bindDom(el, context);
    return el.childNodes;
  };

  Component.prototype.delay = function(delay_time, callback) {
    var ref, timer;
    if (Utils.isFunction(delay_time)) {
      ref = [0, delay_time], delay_time = ref[0], callback = ref[1];
    }
    timer = setTimeout(callback, delay_time);
    return this.addReleaseCallback(function() {
      return clearTimeout(timer);
    });
  };

  Component.prototype.trigger = function(name, data) {
    return this.__element.dispatchEvent(this.__element.createEvent(name, {
      detail: data,
      bubbles: true,
      cancelable: true
    }));
  };

  Component.prototype.on = function(name, handler) {
    this.__element.addEventListener(name, handler);
    return this.addReleaseCallback((function(_this) {
      return function() {
        return _this.__element.removeEventListener(name, handler);
      };
    })(this));
  };

  Component.prototype.listenTo = function(emitter, key, fn) {
    emitter.on(key, fn);
    return this.addReleaseCallback((function(_this) {
      return function() {
        return emitter.off(key, fn);
      };
    })(this));
  };

  return Component;

})();
