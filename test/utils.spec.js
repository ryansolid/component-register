const { toProperty } = require("../lib/component-register");

describe('Test Helpers', () => {
  it('should convert attribute to Property name', () => {
    expect(toProperty('my-custom-attribute')).toBe('myCustomAttribute');
  })
})