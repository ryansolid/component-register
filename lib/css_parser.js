var ComponentParser, HOST, HOSTCONTEXT, NodeFactory, SLOTTED,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

NodeFactory = require('shady-css-parser').NodeFactory;

SLOTTED = /(?:::slotted)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/;

HOST = /(:host)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/;

HOSTCONTEXT = /(:host-context)(?:\(((?:\([^)(]*\)|[^)(]*)+?)\))/;

module.exports = ComponentParser = (function(superClass) {
  extend(ComponentParser, superClass);

  function ComponentParser(tag_name) {
    this.tag_name = tag_name;
  }

  ComponentParser.prototype.ruleset = function(selector, rulelist) {
    var i, j, len, part, parts;
    parts = selector.split(',');
    for (i = j = 0, len = parts.length; j < len; i = ++j) {
      part = parts[i];
      parts[i] = (function() {
        switch (false) {
          case part.indexOf('::slotted') === -1:
            return part.replace(SLOTTED, (function(_this) {
              return function(m, c, expr) {
                return _this.tag_name + ' > ' + expr;
              };
            })(this));
          case part.indexOf(':host-context') === -1:
            return part.replace(HOSTCONTEXT, (function(_this) {
              return function(m, c, expr) {
                return "" + _this.tag_name + expr;
              };
            })(this)) + part.replace(HOSTCONTEXT, (function(_this) {
              return function(m, c, expr) {
                return ", " + expr + " " + _this.tag_name;
              };
            })(this));
          case part.indexOf(':host(') === -1:
            return part.replace(HOST, (function(_this) {
              return function(m, c, expr) {
                return "" + _this.tag_name + expr;
              };
            })(this));
          default:
            return this.tag_name + ' ' + part.replace(':host', '');
        }
      }).call(this);
    }
    selector = parts.join(',');
    return ComponentParser.__super__.ruleset.call(this, selector, rulelist);
  };

  return ComponentParser;

})(NodeFactory);
