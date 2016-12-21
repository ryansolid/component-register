Introduction
============

Component Register is wrapper around the V1 Webcomponent Standard with the intention of providing a convention around what I feel are 2 short comings of the standard.

1.  All arguments are passed through attribute strings. This library uses a convention to pass javascript objects to components.
2.  The named slot mechanism has limits to what it can do in terms of modern templated frameworks. To do things like loops or wrappers around lists of specific slotted content can be complicated. More so when you want to pass mapped information between component and parent context. React passes the mechanism back to the consumer to render the template (and effectively own the context).

It is the intention of this library to provide a framework agnostic base for webcomponents by the use of simple drivers which extend the functionality of the component base class.  Unlike Polymer this is not a full framework with binding language and syntax.  All the mechanism used are pure JS with the expectation that to be used with any existing framework one would simply extend the convention into your own base component classes. In so like the standard itself you aren't tied to a specific framework and can mix and match as you see fit.

Currently this library forces Shadow DOM polyfill across browsers even if there is native support since components would look different in different browsers otherwise due to limitations of the polyfills. In addition some browsers support part of the standard so trying to go to that fine grain level especially where some features can't be performantly polyfilled is a substantial effort.

TODO: Write documentation

TODO: Write tests
