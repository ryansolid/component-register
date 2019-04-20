const { hot, register } = require('../lib/component-register');

let instantiationCount;
register('my-comp')(() => instantiationCount++ );

describe('Mock Webpack Style', () => {
  let status = 'idle',
    accepted = false,
    mockError = false;

  const mockModule = {
    hot: {
      accept(fn) {
        if (mockError) {
          fn(new Error('Mock Error'));
          return;
        }
        accepted = true;
      },
      status() { return status; }
    }
  }

  it('should register acceptance', () => {
    expect(accepted).toBe(false);
    hot(mockModule, 'my-comp');
    expect(accepted).toBe(true);
    accepted = false;
  });

  it('should handle error during acceptance', () => {
    expect(accepted).toBe(false);
    mockError = true;
    hot(mockModule, 'my-comp');
    expect(accepted).toBe(false);
    mockError = false;
  });

  it('should retrigger Component on reload', done => {
    instantiationCount = 0;
    expect(instantiationCount).toBe(0);
    document.body.appendChild(document.createElement('my-comp'));
    expect(instantiationCount).toBe(1);
    status = 'apply';
    expect(accepted).toBe(false);
    hot(mockModule, 'my-comp');
    expect(accepted).toBe(true);
    setTimeout(() => {
      expect(instantiationCount).toBe(2);
      done();
    }, 0);
  });
});

describe('Mock Parcel Style', () => {
  let accepted = false,
    initial = true;

  const mockModule = {
    hot: {
      accept(fn) {
        !initial && fn();
        initial = false;
        accepted = true;
      }
    }
  }

  it('should register acceptance', () => {
    expect(accepted).toBe(false);
    hot(mockModule, 'my-comp');
    expect(accepted).toBe(true);
    accepted = false;
  });

  it('should retrigger Component on reload', done => {
    instantiationCount = 0;
    expect(instantiationCount).toBe(0);
    document.body.innerHTML = '';
    document.body.appendChild(document.createElement('my-comp'));
    expect(instantiationCount).toBe(1);
    expect(accepted).toBe(false);
    hot(mockModule, 'my-comp');
    expect(accepted).toBe(true);
    setTimeout(() => {
      expect(instantiationCount).toBe(2);
      done();
    }, 0);
  });
});