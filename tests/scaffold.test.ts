import { describe, expect, it } from 'vitest';

describe('scaffold', () => {
  it('has a browser-like test environment', () => {
    expect(document.createElement('canvas').tagName).toBe('CANVAS');
  });
});
