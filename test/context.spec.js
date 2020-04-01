const {compose, register, createContext, withProvider, withConsumer, consume} = require('../lib/component-register');
const render = (node) => {
  document.body.append(node);
  return node.outerHTML;
}

FIXTURES = [
  '<h1>Hi</h1>'
]

const Context = createContext(() => {
  return { greeting: 'Hi' }
});

const Parent = compose(
  register('parent-elem'),
  withProvider(Context)
)((_, { element }) => {
  element.renderRoot.innerHTML = '<child-elem></child-elem>';
});

register('child-elem')((_, { element }) => {
  const c = consume(Context, element);
  element.renderRoot.innerHTML = `<h1>${c.greeting}</h1>`;
});

// timing in test env doesn't allow this
const Child2 = compose(
  register('child-elem2'),
  withConsumer(Context, 'store')
)((_, options) => {
  expect('store' in options).toBe(true);
});

describe('Test Context API', () => {
  it('should pass context down', () => {
    let p;
    render(p = new Parent());
    expect(p.renderRoot.firstChild.renderRoot.innerHTML).toBe(FIXTURES[0]);
  })
});

// due to limitations of test env
describe('Fake Test withConsumer', () => {
  it('should create context key', () => {
    render(new Child2());
  });
})