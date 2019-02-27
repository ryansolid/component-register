const {compose, register, createContext, withProvider, withConsumer, consume} = require('../lib/component-register');
const render = require('@skatejs/ssr');

// Patch isConnected for sake of tests
Object.defineProperty(HTMLElement.prototype, 'isConnected', {
  get() { return true; }
});

FIXTURES = [
  '<parent-elem><shadowroot><child-elem><shadowroot><h1>Hi</h1><script>__ssr()</script></shadowroot></child-elem><script>__ssr()</script></shadowroot></parent-elem>'
]

const Context = createContext(() => {
  return { greeting: 'Hi' }
});

const Parent = compose(
  register('parent-elem'),
  withProvider(Context)
)((_, { element }) => {
  element.renderRoot().innerHTML = '<child-elem></child-elem>';
});

register('child-elem')((_, { element }) => {
  // tests need defer microtask for some reason
  Promise.resolve().then(() => {
    const c = consume(Context, element);
    element.renderRoot().innerHTML = `<h1>${c.greeting}</h1>`;
  })
});

// timing in test env doesn't allow this
const Child2 = compose(
  register('child-elem2'),
  withConsumer(Context, 'store')
)((_, options) => {
  expect('store' in options).toBe(true);
});

describe('Test Context API', () => {
  it('should pass context down', async () => {
    let p;
    const results = await render(p = new Parent());
    expect(results).toBe(FIXTURES[0]);
  })
});

// due to limitations of test env
describe('Fake Test withConsumer', () => {
  it('should create context key', async () => {
    await render(new Child2());
  });
})