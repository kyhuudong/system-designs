import { describe, it, expect, beforeEach } from 'vitest';
import { MissingEnvError, getBool, getInt, getStr, require_ } from './env.js';

describe('env', () => {
  beforeEach(() => {
    for (const k of Object.keys(process.env)) {
      if (k.startsWith('TEST_RECIPE_')) delete process.env[k];
    }
  });

  it('getStr returns value when set, default when missing', () => {
    process.env.TEST_RECIPE_FOO = 'bar';
    expect(getStr('TEST_RECIPE_FOO')).toBe('bar');
    expect(getStr('TEST_RECIPE_MISSING', 'fallback')).toBe('fallback');
    expect(getStr('TEST_RECIPE_MISSING')).toBeUndefined();
  });

  it('getInt parses numbers, throws on non-numeric', () => {
    process.env.TEST_RECIPE_PORT = '8080';
    expect(getInt('TEST_RECIPE_PORT')).toBe(8080);
    process.env.TEST_RECIPE_PORT = 'abc';
    expect(() => getInt('TEST_RECIPE_PORT')).toThrow();
  });

  it('getBool handles truthy and falsy values', () => {
    for (const truthy of ['1', 'true', 'TRUE', 'yes', 'on']) {
      process.env.TEST_RECIPE_FLAG = truthy;
      expect(getBool('TEST_RECIPE_FLAG')).toBe(true);
    }
    for (const falsy of ['0', 'false', 'FALSE', 'no', 'off', '']) {
      process.env.TEST_RECIPE_FLAG = falsy;
      expect(getBool('TEST_RECIPE_FLAG')).toBe(false);
    }
    process.env.TEST_RECIPE_FLAG = 'maybe';
    expect(() => getBool('TEST_RECIPE_FLAG')).toThrow();
  });

  it('require_ throws MissingEnvError when not set', () => {
    expect(() => require_('TEST_RECIPE_MUST')).toThrow(MissingEnvError);
    process.env.TEST_RECIPE_MUST = 'ok';
    expect(require_('TEST_RECIPE_MUST')).toBe('ok');
  });
});
