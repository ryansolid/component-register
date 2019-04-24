import { createMixin } from './mixin';
import { getCurrentElement } from './element';

const EC = Symbol('element-context');

interface Context { id: symbol, initFn: Function };
type WalkableNode = Node & {
  host?: WalkableNode
  [EC]?: any
}

function lookupContext(element: WalkableNode, context: Context): any {
  return (element[EC] && element[EC][context.id]) || ((element.host || element.parentNode) && lookupContext((element.host || element.parentNode) as WalkableNode, context));
}

export function createContext(initFn: Function): Context {
  return { id: Symbol('context'), initFn };
}

// Direct
export function provide(context: Context, value: any, element: WalkableNode = getCurrentElement()) {
  element[EC] || (element[EC] = {});
  return element[EC][context.id] = context.initFn ? context.initFn(value): value;
}

export function consume(context: Context, element = getCurrentElement()) {
  return lookupContext(element, context);
}

// HOCs
export function withProvider(context: Context, value: any) {
  return createMixin((options: any) => {
    const { element } = options;
    provide(context, value, element);
    return options;
  });
}

export function withConsumer(context: Context, key: string) {
  return createMixin((options: any) => {
    const { element } = options;
    options = {...options, [key]: lookupContext(element, context)};
    return options;
  });
}