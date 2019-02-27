const { connectedToDOM, toComponentName, toProperty } = require("../lib/component-register");

delete HTMLElement.prototype.isConnected;

describe('Test Helpers', () => {
  it('should fallback testing DOM connectivity', () => {
    const div = document.createElement('div');
    expect(connectedToDOM(div)).toBe(false);
  });
  it('should convert tag to Component name', () => {
    expect(toComponentName('my-custom-elem')).toBe('MyCustomElem');
  });
  it('should convert attribute to Property name', () => {
    expect(toProperty('my-custom-attribute')).toBe('myCustomAttribute');
  })
})