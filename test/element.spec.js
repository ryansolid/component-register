const { register, getCurrentElement } = require('../lib/component-register');

const FIXTURES = [
  '<h1>Hello John 0</h1>',
  '<h1>Hello Jake 0</h1>',
  '<h1>Hello Matt 123</h1>',
  '<h1>Hello  123</h1>',
  '<h1>Hello Nate 123</h1>'
]

let TestElem, elem;

describe('Creating a Custom Element', () => {
  it('should register a component', () => {
    register('test-elem', {
      name: {value: 'John', notify: true, reflect: true},
      number: 0,
      callbackFn: () => {},
      model: {id: 2},
      list: []
    })((props, { element }) => {
      const render = props => element.renderRoot.innerHTML = `<h1>Hello ${props.name} ${props.number}</h1>`;

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

  it('should upgrade element connected to DOM', () => {
    elem = new TestElem();
    document.body.append(elem);
    expect(elem.renderRoot.innerHTML).toBe(FIXTURES[0]);
  });

  it('should update props directly', () => {
    elem.name = 'Jake';
    expect(elem.renderRoot.innerHTML).toBe(FIXTURES[1]);
  });

  it('should update by attribute', () => {
    elem.setAttribute('name', 'Matt');
    elem.setAttribute('number', '123');
    expect(elem.name).toBe('Matt');
    expect(elem.renderRoot.innerHTML).toBe(FIXTURES[2]);
  });

  it('should clear prop', () => {
    elem.name = '';
    expect(elem.renderRoot.innerHTML).toBe(FIXTURES[3]);
  });

  it('should cleanup on disconnect', (done) => {
    document.body.remove(elem);
    setTimeout(() => {
      expect(elem.__released).toBe(true);
      expect(elem.releasedWasCalled).toBe(true);
      done();
    }, 0);
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
  it('should not catch component if error', () => {
    const ErrElem = register('err-elem')(class {
      constructor() { throw new Error('Trouble'); }
    });
    expect(() => {
      document.body.append(new ErrElem());
    }).toThrow()
  })
});