import { isConstructor } from './utils';

export function createMixin(mixinFn) {
  return ComponentType =>
    options => {
      options = mixinFn(options);
      if (isConstructor(ComponentType)) return new ComponentType(options);
      return ComponentType(options);
    }
}
