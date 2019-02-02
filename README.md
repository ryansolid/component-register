# Component Register

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple functional composition to wrap components from existing libraries.  The expectation is to be used with any existing framework one would simply wrap.

This library is designed to work in environments that already support custom elements, templates, and shadow dom. If those are not present your target browser can include the [component-register-platform](https://github.com/ryansolid/component-register-platform) shim which includes some ES2015 and webcomponents.js polyfills to give support back to IE11. Alternatively for more modern browsers without full support the webcomponents.js polyfills will do the trick.

## Getting Started

The simplest use would be:

```js
import { register } from 'component-register';

register('my-element')((props, { element }) =>
  element.renderRoot().innerHTML = 'Hello World'
)
```

This creates a custom element with the tag 'my-element' and the text 'Hello World' in its shadow root.

You can also define props by giving a name and a default value:

```js
import { register } from 'component-register';

register('my-greeting', {name: 'World'})((props, { element }) =>
  element.renderRoot().innerHTML = `Hello ${props.name}`
)
```

These props map to both element[propName] and an attribute prop-name. Alternatively you can initialize props with an object which has properties value (default value), notify (fire an event on change, for 2 way binding libraries), and attribute (if you want to name the attribute for the prop differently than the default).

You can register a callback handler via:

### element.addPropertyChangedCallback(fn)

The function handler is passed (name, value, prevValue).

You can also register a release callback via:

### element.addReleaseCallback(fn)

Functions registered this way will be called when the component has been removed from the DOM for full Macrotask cycle.

With these 2 methods its very easy to write mixins that can react to changes and cleanup after themselves. The library includes createMixin as an easy way to add behavior to your elements. For example making a mixin to make a Component draggable with optional opacity on drag:

```js
import { createMixin } from 'component-register';

export default function withDraggable({opacity} = {}) {
  return createMixin((options) => {
    let { element } = options,
      pos1, pos2, pos3, pos4;
    pos1 = pos2 = pos3 = pos4 = null;
    element.style.position = 'absolute';
    element.onmousedown = function(e) {
      pos3 = e.clientX;
      pos4 = e.clientY;
      if (opacity != null) {
        element.style.opacity = opacity;
      }
      document.onmouseup = closeDragElement;
      document.onmousemove = elementDrag;
    };
    function elementDrag(e) {
      pos1 = pos3 - e.clientX;
      pos2 = pos4 - e.clientY;
      pos3 = e.clientX;
      pos4 = e.clientY;
      element.style.top = (element.offsetTop - pos2) + "px";
      element.style.left = (element.offsetLeft - pos1) + "px";
    };
    function closeDragElement() {
      if (opacity != null) {
        element.style.opacity = 1;
      }
      document.onmouseup = null;
      document.onmousemove = null;
    };
    return options;
  });
}
```

To use this mixin you would just wrap your component like so:

```js
import { register } from 'component-register';

register('my-draggable')(withDraggable({opacity: 0.6})((props, { element }) =>
  // ....
))
```

Or using compose:
```js
import { register, compose } from 'component-register';

compose(
  register('my-draggable'),
  withDraggable({opacity: 0.6})
)(props, { element }) =>
  // ....
))
```

[component-register-extensions](https://github.com/ryansolid/component-register-extensions) includes some other examples of simple mixins.

Alternative the library exposes a ```getCurrentElement()``` method that can be used to create mixins that can be added in the constructor or initialization function of the component without explicitly passing in the element.

## Context API

For dependency injection this library supports a Provider/Consumer Context API.

### createContext(initFn): ContextObject

If an init function is provided it will be called by the provider on creation with the provided value.

### withProvider(context, initialValue)
### provide(context, initialValue)

HOC and direct method for adding a new provider instance of the supplied context in the render tree.

### withConsumer(context, key)
### consume(context): contextInstance

HOC mixins in context for the component on that key and direct method returns the context instance.

```jsx
// counter.js
import { createContext } from 'component-register';

/* You can put whatever you want in here, as this container is not responsible for the reactivity of your application you need to provide your own mechanisms. */
export createContext((count = 0) => {
  return [count, {
    increment() { count += 1; }
    decrement() { count -= 1; }
  }];
});

// app.js
import { register, compose, withProvider } from 'component-register';
import CounterContext from './counter';

const AppComponent = /* Some component */

compose(
  register('app-component'),
  withProvider(CounterContext)
)(AppComponent);

// nested.js
import { register, compose, withConsumer } from 'component-register';
import CounterContext from './counter';

const NestedComponent = (props, { counter }) => { /* ... */ }

compose(
  register('nested-component'),
  withConsumer(CounterContext, 'counter')
)(NestedComponent);
```

## Examples

* [component-register-preact](https://github.com/ryansolid/component-register-react) This implementation to demonstrate using Preact Components as is as Custom Elements.

* [component-register-react](https://github.com/ryansolid/component-register-react) This implementation to demonstrate using React Components as is as Custom Elements.

* [solid-components](https://github.com/ryansolid/solid-components) Component implementation for [Solid](https://github.com/ryansolid/solid) that showcases some more powerful usage of the library.

* [component-register-ko](https://github.com/ryansolid/component-register-ko) The project where I started experimenting with generalizing webcomponents. It has a lot of extras but is good example of a template based rendering library with fine grained KVO (key value observable) change detection and support for 2 way binding.

## Status

This library over time has been made smaller as the polyfills have been removed. The external API is mostly stable