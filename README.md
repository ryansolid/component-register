Introduction
============

Component Register is wrapper around the V1 Webcomponent Standard with the intention of providing a convention around the shortcoming of the standard where all arguments are passed through attribute strings. This library uses a convention to pass non-basic values as element properties.

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple drivers which extend the functionality of the component base class.  Unlike Polymer this is not a full framework with binding language and syntax.  All the mechanism used are pure JS with the expectation that to be used with any existing framework one would simply extend the convention into your own base component classes. In so like the standard itself you aren't tied to a specific framework and can mix and match as you see fit.

This library is designed to work in environments that already support custom elements, templates, and shadow dom. If those are not present your target browser can include the [component-register-platform](https://github.com/ryansolid/component-register-platform) shim which includes some ES2015 and webcomponents.js polyfills to give support back to IE11. Alternatively for more modern browsers without full support the webcomponents.js polyfills will do the trick.

TODO: Write documentation

TODO: Write tests
