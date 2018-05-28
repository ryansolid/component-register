# Component Register

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple functional composition to wrap components from existing libraries.  Unlike Polymer this is not a full framework with binding language and syntax.  All the mechanism used are pure JS with the expectation that to be used with any existing framework one would simply wrap.

This library is designed to work in environments that already support custom elements, templates, and shadow dom. If those are not present your target browser can include the [component-register-platform](https://github.com/ryansolid/component-register-platform) shim which includes some ES2015 and webcomponents.js polyfills to give support back to IE11. Alternatively for more modern browsers without full support the webcomponents.js polyfills will do the trick.

## Getting Started

The simplest use would be:

    import { register } from 'component-register';

    register('my-element')(({ element }) =>
      element.renderRoot().innerHTML = 'Hello World'
    )

This creates a custom element with the tag 'my-element' and the text 'Hello World' in its shadow root.

You can also define props by giving a name and a default value:

    import { register } from 'component-register';

    register('my-greeting', {name: 'World'})(({ element, props }) =>
      element.renderRoot().innerHTML = `Hello ${props.name}`
    )

These props map to both element[propName] and an attribute prop-name. You can register a callback handler via:

### element.addPropertyChangedCallback(fn)

The function handler is passed (name, value, prevValue).

You can also register a release callback via:

### element.addReleaseCallback(fn)

Functions registered this way will be called when the component has been removed from the DOM for full Macrotask cycle.

With these 2 methods its very easy to write mixins that can react to changes and cleanup after themselves. The library includes createMixin as an easy way to add behavior to your elements. For example making a mixin to make a Component draggable with optional opacity on drag:

    import { createMixin } from 'component-register';

    export default withDraggable = function({opacity} = {}) {
      return createMixin(function(options) {
        var closeDragElement, element, elementDrag, pos1, pos2, pos3, pos4;
        ({element} = options);
        pos1 = pos2 = pos3 = pos4 = null;
        element.style.position = 'absolute';
        element.onmousedown = function(e) {
          pos3 = e.clientX;
          pos4 = e.clientY;
          if (opacity != null) {
            element.style.opacity = opacity;
          }
          document.onmouseup = closeDragElement;
          return document.onmousemove = elementDrag;
        };
        elementDrag = function(e) {
          pos1 = pos3 - e.clientX;
          pos2 = pos4 - e.clientY;
          pos3 = e.clientX;
          pos4 = e.clientY;
          element.style.top = (element.offsetTop - pos2) + "px";
          return element.style.left = (element.offsetLeft - pos1) + "px";
        };
        closeDragElement = function() {
          if (opacity != null) {
            element.style.opacity = 1;
          }
          document.onmouseup = null;
          return document.onmousemove = null;
        };
        return options;
      });
    }

To use this mixin you would just wrap your component like so:

    import { register } from 'component-register';

    register('my-draggable')(withDraggable({opacity: 0.6})(({ element }) =>
      element.renderRoot().innerHTML = 'Hello World'
    ))

Or using compose:
    import { register, compose } from 'component-register';

    compose(
      register('my-draggable'),
      withDraggable({opacity: 0.6})
    )({ element }) =>
      element.renderRoot().innerHTML = 'Hello World'
    ))

[component-register-extensions](https://github.com/ryansolid/component-register-extensions) includes some other examples of simple mixins.

## Examples

* [component-register-ko](https://github.com/ryansolid/component-register-ko) The project where I started experimenting with generalizing webcomponents. It has a lot of extras but is good example of a template based rendering library.

* [component-register-react](https://github.com/ryansolid/component-register-react) This is very light implementation to demonstrate using React Components as is as Custom Elements.

## Status

This library over time has been made smaller as the polyfills have been removed. 0.4.0 breaks out a much simpler API. However, still playing catch up on Documentation and Tests.