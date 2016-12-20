var ComponentRegistry, utils;

utils = require('./utils');

module.exports = ComponentRegistry = (function() {
  function ComponentRegistry() {}

  ComponentRegistry.register = function(component) {
    var name, tag;
    if (!(tag = component != null ? component.tag : void 0)) {
      return console.error('Component missing static tag property');
    }
    name = utils.toComponentName(tag.toLowerCase());
    if (ComponentRegistry[name]) {
      return console.error("Component already registered: " + name);
    }
    return ComponentRegistry[name] = component;
  };

  return ComponentRegistry;

})();
