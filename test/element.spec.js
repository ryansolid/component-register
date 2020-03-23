const { register, getCurrentElement } = require('../lib/component-register');
const render = require('@skatejs/ssr');

// Patch isConnected for sake of tests
let connected;
Object.defineProperty(HTMLElement.prototype, 'isConnected', {
  get() { return connected; }
});

const FIXTURES = [
  '<test-elem name="John"><shadowroot><h1>Hello John</h1><script>__ssr()</script></shadowroot></test-elem>',
  '<test-elem name="Jake"><shadowroot><h1>Hello Jake</h1><script>__ssr()</script></shadowroot></test-elem>',
  '<test-elem name="Matt"><shadowroot><h1>Hello Matt</h1><script>__ssr()</script></shadowroot></test-elem>',
  '<test-elem><shadowroot><h1>Hello </h1><script>__ssr()</script></shadowroot></test-elem>',
  '<test-elem name="Nate"><shadowroot><h1>Hello Nate</h1><script>__ssr()</script></shadowroot></test-elem>'
]

let TestElem, elem;

describe('Creating a Custom Element', () => {
  it('should register a component', () => {
    register('test-elem', {
      name: {value: 'John', notify: true},
      callbackFn: () => {},
      model: {id: 2},
      list: []
    })((props, { element }) => {
      const render = props => element.renderRoot.innerHTML = `<h1>Hello ${props.name}</h1>`;

      expect(getCurrentElement()).toBe(element);

      element.addPropertyChangedCallback((name, value) => {
        props[name] = value;
        render(props);
      });

      element.addReleaseCallback(() => {
        element.releasedWasCalled = true;
      });

      render(props);
    });
    TestElem = customElements.get('test-elem');
    expect(TestElem).toBeDefined();
  });

  it('should upgrade element connected to DOM and cleanup on disconnect', async done => {
    connected = true;
    const results = await render(elem = new TestElem());
    expect(results).toBe(FIXTURES[0]);
    connected = false;
    setTimeout(() => {
      expect(elem.__released).toBe(true);
      expect(elem.releasedWasCalled).toBe(true);
      // set up rest of tests
      connected = true;
      done();
    }, 0);
  });

  it('should update props directly', async () => {
    elem.name = 'Jake';
    const results = await render(elem);
    expect(results).toBe(FIXTURES[1]);
  });

  it('should update by attribute', async () => {
    elem.setAttribute('name', 'Matt');
    expect(elem.name).toBe('Matt');
    const results = await render(elem);
    expect(results).toBe(FIXTURES[2]);
  });

  it('should clear prop', async () => {
    elem.name = '';
    const results = await render(elem);
    expect(results).toBe(FIXTURES[3]);
  });

  it('should be able to setProperty for two-way binding', async () => {
    elem.setProperty('name', 'Nate');
    const results = await render(elem);
    expect(results).toBe(FIXTURES[4]);
  });

  it('should trigger event', async () => {
    elem.oncustom = jest.fn();
    elem.trigger('custom');
    expect(elem.oncustom).toBeCalled();
  });
});

describe('Test register exceptions', () => {
  it('should handle already registered tag', () => {
    const Duplicate = register('test-elem')(() => {});
    expect(Duplicate).toBe(TestElem);
  });
  it('should error with no tag', () => {
    expect(() => register()()).toThrow();
  });
  it('should catch component it error', () => {
    const ErrElem = register('err-elem')(class {
      constructor() { throw new Error('Trouble'); }
    });
    expect(async () => {
      await render(new ErrElem());
    }).not.toThrow()
  })
});