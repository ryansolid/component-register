import { isConstructor, ComponentType, ConstructableComponent, FunctionComponent } from './utils';

export function createMixin(mixinFn: (options: object) => object) {
  return (ComponentType: ComponentType) =>
    ((props: object, options: object) => {
      options = mixinFn(options);
      if (isConstructor(ComponentType)) return new (ComponentType as ConstructableComponent)(props, options);
      return (ComponentType as FunctionComponent)(props, options);
    }) as ComponentType
}

export function compose(...fns: ((C: ComponentType) => ComponentType)[]) {
  if (fns.length === 0) return (i: ComponentType) => i;
  if (fns.length === 1) return fns[0];
  return fns.reduce((a, b) => (...args) => a(b(...args)));
}
