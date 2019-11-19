import {
  isConstructor,
  ComponentType,
  ConstructableComponent,
  FunctionComponent,
  ComponentOptions
} from "./utils";

export function createMixin(
  mixinFn: (options: ComponentOptions) => ComponentOptions
) {
  return (ComponentType: ComponentType<any>) =>
    ((props: any, options: ComponentOptions) => {
      options = mixinFn(options);
      if (isConstructor(ComponentType))
        return new (ComponentType as ConstructableComponent<any>)(props, options);
      return (ComponentType as FunctionComponent<any>)(props, options);
    }) as ComponentType<any>;
}

export function compose(...fns: ((C: ComponentType<any>) => ComponentType<any>)[]) {
  if (fns.length === 0) return (i: ComponentType<any>) => i;
  if (fns.length === 1) return fns[0];
  return fns.reduce((a, b) => (...args) => a(b(...args)));
}
