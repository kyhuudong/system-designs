// Recipe: exponential-backoff retry helper
// Stdlib-only.
// Usage:
//   import { retry, RetryError } from './retry.js';
//
//   const data = await retry(() => fetch(url), { maxAttempts: 5, baseDelayMs: 100 });
//
// Errors that aren't instances of any class in `only` propagate immediately.
// After maxAttempts failures the last caught error is re-thrown wrapped in RetryError.

export class RetryError extends Error {
  constructor(message: string, readonly cause: unknown) {
    super(message);
    this.name = 'RetryError';
  }
}

export interface RetryOptions {
  maxAttempts?: number;
  baseDelayMs?: number;
  maxDelayMs?: number;
  jitter?: number;
  /** Error classes to catch and retry. Anything else propagates. */
  only?: Array<abstract new (...args: never[]) => Error>;
}

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelayMs = 100,
    maxDelayMs = 30_000,
    jitter = 0.1,
    only = [Error],
  } = options;

  if (maxAttempts < 1) {
    throw new Error('maxAttempts must be >= 1');
  }

  let lastErr: unknown;
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      return await fn();
    } catch (err) {
      const matches = only.some((Klass) => err instanceof Klass);
      if (!matches) throw err;
      lastErr = err;
      if (attempt === maxAttempts - 1) break;
      let delay = Math.min(baseDelayMs * 2 ** attempt, maxDelayMs);
      if (jitter > 0) delay += Math.random() * delay * jitter;
      await sleep(delay);
    }
  }
  throw new RetryError(`retried ${maxAttempts} times`, lastErr);
}
