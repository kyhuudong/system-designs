import { describe, it, expect, vi } from 'vitest';
import { retry, RetryError } from './retry.js';

describe('retry', () => {
  it('returns the first successful result without sleeping', async () => {
    const fn = vi.fn(async () => 42);
    const result = await retry(fn, { maxAttempts: 3, baseDelayMs: 0 });
    expect(result).toBe(42);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('retries on failure and succeeds within max attempts', async () => {
    let n = 0;
    const fn = vi.fn(async () => {
      n += 1;
      if (n < 3) throw new Error('nope');
      return 'ok';
    });
    const result = await retry(fn, { maxAttempts: 5, baseDelayMs: 0 });
    expect(result).toBe('ok');
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('throws RetryError after exhausting attempts', async () => {
    const fn = vi.fn(async () => {
      throw new Error('always');
    });
    await expect(retry(fn, { maxAttempts: 3, baseDelayMs: 0 })).rejects.toBeInstanceOf(RetryError);
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('does not retry errors outside `only`', async () => {
    class TransientError extends Error {}
    class FatalError extends Error {}
    const fn = vi.fn(async () => {
      throw new FatalError('boom');
    });
    await expect(
      retry(fn, { maxAttempts: 5, baseDelayMs: 0, only: [TransientError] }),
    ).rejects.toBeInstanceOf(FatalError);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('uses exponential backoff base delay', async () => {
    let n = 0;
    const fn = vi.fn(async () => {
      n += 1;
      throw new Error('nope');
    });
    const start = Date.now();
    await retry(fn, { maxAttempts: 3, baseDelayMs: 50, jitter: 0 }).catch(() => undefined);
    const elapsed = Date.now() - start;
    expect(elapsed).toBeGreaterThanOrEqual(100);
  });
});
