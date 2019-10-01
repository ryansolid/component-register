import { isConstructor, ComponentType, ConstructableComponent, FunctionComponent, Props, ComponentOptions } from './utils';

export function createMixin(mixinFn: (options: ComponentOptions) => ComponentOptions) {
  return (ComponentType: ComponentType) =>
    ((props: Props, options: ComponentOptions) => {
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
