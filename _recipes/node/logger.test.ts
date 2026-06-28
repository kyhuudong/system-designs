import { describe, it, expect } from 'vitest';
import { Writable } from 'node:stream';
import { createLogger } from './logger.js';

function collect(): { stream: Writable; lines: () => string[] } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk, _enc, cb) {
      chunks.push(chunk.toString());
      cb();
    },
  });
  return { stream, lines: () => chunks.join('').split('\n').filter(Boolean) };
}

describe('logger', () => {
  it('emits a JSON line per log call', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'info' });
    log.info('hello', { userId: 42 });
    const out = lines();
    expect(out).toHaveLength(1);
    const payload = JSON.parse(out[0]);
    expect(payload.level).toBe('info');
    expect(payload.logger).toBe('app');
    expect(payload.message).toBe('hello');
    expect(payload.userId).toBe(42);
    expect(payload.timestamp).toEqual(expect.any(String));
  });

  it('respects the level threshold', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'warn' });
    log.info('ignored');
    log.warn('kept');
    const out = lines();
    expect(out).toHaveLength(1);
    expect(JSON.parse(out[0]).message).toBe('kept');
  });

  it('serializes Error instances', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'error' });
    log.error('oops', { err: new Error('boom') });
    const payload = JSON.parse(lines()[0]);
    expect(payload.err.name).toBe('Error');
    expect(payload.err.message).toBe('boom');
    expect(payload.err.stack).toEqual(expect.any(String));
  });
});
