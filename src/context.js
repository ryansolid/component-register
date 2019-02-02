import { createMixin } from './mixin';
import { getCurrentElement } from './element';

const EC = Symbol('element-context');

function lookupContext(element, context) {
  return (element[EC] && element[EC][context.id]) || ((element.host || element.parentNode) && lookupContext(element.host || element.parentNode, context));
}

export function createContext(initFn) {
  return { id: Symbol('context'), initFn };
}

// Direct
export function provide(context, value, element = getCurrentElement()) {
  element[EC] || (element[EC] = {});
  element[EC][context.id] = context.initFn ? context.initFn(value): value;
}

export function consume(context) {
  const element = getCurrentElement();
  return lookupContext(element, context);
}

// HOCs
export function withProvider(context, value) {
  return createMixin(options => {
    const { element } = options;
    provide(context, value, element);
    return options;
  });
}

export function withConsumer(context, key) {
  return createMixin(options => {
    const { element } = options;
    options = {...options, [key]: lookupContext(element, context)};
    return options;
  });
}