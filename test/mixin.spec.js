const render = require('@skatejs/ssr');
const {register, createMixin, compose} = require('../lib/component-register');

// Patch isConnected for sake of tests
Object.defineProperty(HTMLElement.prototype, 'isConnected', {
  get() { return true; }
});

const FIXTURES = [
  '<mixin-elem toggled="true"></mixin-elem>',
  '<class-elem toggled="true"></class-elem>'
]

const toggleMixin = createMixin(options => {
  const { element } = options,
    toggle = () => element.setAttribute('toggled', !element.getAttribute('toggled'));
  return { ...options, toggle };
});

describe('Creating Mixin', () => {
  it('should apply mixin to fn component', async () => {
    const MixinElem = compose(
      register('mixin-elem'),
      toggleMixin
    )((_, { toggle }) => toggle());
    const results = await render(new MixinElem());
    expect(results).toBe(FIXTURES[0]);
  });
  it('should apply mixin to class component', async () => {
    const ClassElem = compose(
      register('class-elem'),
      toggleMixin
    )(class {
      constructor(_, { toggle }) { toggle(); }
    });
    const results = await render(new ClassElem());
    expect(results).toBe(FIXTURES[1]);
  });
});

describe('Testing compose', () => {
  it('should handle no arguments', () => {
    const fn = compose(),
      ref = {};

    expect(fn(ref)).toBe(ref);
  });
  it('should handle single argument', () => {
    const fn = () => {};

    expect(compose(fn)).toBe(fn);
  });
})