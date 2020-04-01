const {register, createMixin, compose} = require('../lib/component-register');

const render = (node) => {
  document.body.append(node);
  return node.outerHTML;
}

const FIXTURES = [
  '<mixin-elem toggled="true"></mixin-elem>',
  '<class-elem toggled="true"></class-elem>'
]

const toggleMixin = createMixin(options => {
  const { element } = options,
    toggle = () => element.setAttribute('toggled', !element.getAttribute('toggled'));
  return Object.assign({}, options, { toggle });
});

describe('Creating Mixin', () => {
  it('should apply mixin to fn component', () => {
    const MixinElem = compose(
      register('mixin-elem'),
      toggleMixin
    )((_, { toggle }) => toggle());
    const results = render(new MixinElem());
    expect(results).toBe(FIXTURES[0]);
  });
  it('should apply mixin to class component', () => {
    const ClassElem = compose(
      register('class-elem'),
      toggleMixin
    )(class {
      constructor(_, { toggle }) { toggle(); }
    });
    const results = render(new ClassElem());
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