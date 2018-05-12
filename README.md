# Component Register

Component Register is wrapper around the V1 Webcomponent Standard with the intention of providing a convention around the shortcoming of the standard where all arguments are passed through attribute strings. This library uses a convention to pass non-basic values as element properties.

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple functional composition to wrap existing components.  Unlike Polymer this is not a full framework with binding language and syntax.  All the mechanism used are pure JS with the expectation that to be used with any existing framework one would simply wrap. In so like the standard itself you aren't tied to a specific framework and can mix and match as you see fit. The register method is setup like a HOC or ESNext decorator and takes a function or class definition as it's parameter and calls it's it with an options object that passes the custom element. Wrapping an existing framework would essentially be adding another HOC in between to map it to the expected constructor format.

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

With these 2 methods its very easy to write HOC mixins that can react to changes and cleanup after themselves. The library includes createMixin as an easy way to add behavior to your elements. For example making a mixin to make a Component draggable with optional opacity on drag:

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
