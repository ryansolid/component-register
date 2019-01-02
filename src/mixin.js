import { isConstructor } from './utils';

export function createMixin(mixinFn) {
  return ComponentType =>
    options => {
      options = mixinFn(options);
      if (isConstructor(ComponentType)) return new ComponentType(options);
      return ComponentType(options);
    }
}

export function compose(...fns) {
  if (fns.length === 0) return i => i;
  if (fns.length === 1) return fns[0];
  return fns.reduce((a, b) => (...args) => a(b(...args)));
}
