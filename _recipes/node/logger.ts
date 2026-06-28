// Recipe: JSON-line structured logger
// Stdlib-only (node:stream, node:process).
// Usage:
//   import { createLogger } from './logger.js';
//   const log = createLogger({ name: 'my-service' });
//   log.info('started', { port: 8080 });
//
// Every call emits one JSON object per line. Custom fields are merged at the
// top level. Error values are serialized as { name, message, stack }.

import { Writable } from 'node:stream';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVELS: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

export interface LoggerOptions {
  name: string;
  level?: LogLevel;
  stream?: Writable;
}

export interface Logger {
  debug: (message: string, fields?: Record<string, unknown>) => void;
  info: (message: string, fields?: Record<string, unknown>) => void;
  warn: (message: string, fields?: Record<string, unknown>) => void;
  error: (message: string, fields?: Record<string, unknown>) => void;
}

function serializeValue(v: unknown): unknown {
  if (v instanceof Error) {
    return { name: v.name, message: v.message, stack: v.stack };
  }
  return v;
}

export function createLogger({
  name,
  level = 'info',
  stream = process.stderr,
}: LoggerOptions): Logger {
  const threshold = LEVELS[level];

  const emit = (lvl: LogLevel, message: string, fields?: Record<string, unknown>): void => {
    if (LEVELS[lvl] < threshold) return;
    const payload: Record<string, unknown> = {
      timestamp: new Date().toISOString(),
      level: lvl,
      logger: name,
      message,
    };
    if (fields) {
      for (const [k, v] of Object.entries(fields)) {
        payload[k] = serializeValue(v);
      }
    }
    stream.write(`${JSON.stringify(payload)}\n`);
  };

  return {
    debug: (m, f) => emit('debug', m, f),
    info: (m, f) => emit('info', m, f),
    warn: (m, f) => emit('warn', m, f),
    error: (m, f) => emit('error', m, f),
  };
}
