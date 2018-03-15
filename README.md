Introduction
============

Component Register is wrapper around the V1 Webcomponent Standard with the intention of providing a convention around the shortcoming of the standard where all arguments are passed through attribute strings. This library uses a convention to pass non-basic values as element properties.

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple functional composition to wrap existing components.  Unlike Polymer this is not a full framework with binding language and syntax.  All the mechanism used are pure JS with the expectation that to be used with any existing framework one would simply wrap. In so like the standard itself you aren't tied to a specific framework and can mix and match as you see fit. The register method is setup like a HOC or ES7 decorator and takes a function or class definition as it's parameter and calls it's it with an options object that passes the custom element. Wrapping an existing framework would essentially be adding another HOC in between to map it to the expected constructor format.

This library is designed to work in environments that already support custom elements, templates, and shadow dom. If those are not present your target browser can include the [component-register-platform](https://github.com/ryansolid/component-register-platform) shim which includes some ES2015 and webcomponents.js polyfills to give support back to IE11. Alternatively for more modern browsers without full support the webcomponents.js polyfills will do the trick.

Example Usage
=============

The simplest use would be:

    import { register } from 'component-register';

    register('my-element')( ({ element }) => {
      element.renderRoot().innerHTML = 'Hello World'
    })

This creates a custom element with the tag 'my-element' and the text 'Hello World' in its shadow root.


TODO: Write tests
