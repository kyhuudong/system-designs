// Recipe: typed env-var loader
// Stdlib-only.
// Usage:
//   import { getInt, getBool, require_ } from './env.js';
//
//   const port = getInt('PORT', 8080);
//   const debug = getBool('DEBUG', false);
//   const dbUrl = require_('DATABASE_URL');  // throws if absent
//
// `require_` is named with an underscore to avoid clashing with CommonJS `require`.

export class MissingEnvError extends Error {
  constructor(name: string) {
    super(`required env var ${name} is not set`);
    this.name = 'MissingEnvError';
  }
}

const TRUE = new Set(['1', 'true', 'yes', 'on']);
const FALSE = new Set(['0', 'false', 'no', 'off', '']);

export function getStr(name: string): string | undefined;
export function getStr(name: string, defaultValue: string): string;
export function getStr(name: string, defaultValue?: string): string | undefined {
  const v = process.env[name];
  return v === undefined ? defaultValue : v;
}

export function getInt(name: string): number | undefined;
export function getInt(name: string, defaultValue: number): number;
export function getInt(name: string, defaultValue?: number): number | undefined {
  const raw = process.env[name];
  if (raw === undefined) return defaultValue;
  if (!/^-?\d+$/.test(raw)) {
    throw new Error(`env ${name}=${JSON.stringify(raw)} is not a valid integer`);
  }
  return Number.parseInt(raw, 10);
}

export function getBool(name: string): boolean | undefined;
export function getBool(name: string, defaultValue: boolean): boolean;
export function getBool(name: string, defaultValue?: boolean): boolean | undefined {
  const raw = process.env[name];
  if (raw === undefined) return defaultValue;
  const low = raw.toLowerCase();
  if (TRUE.has(low)) return true;
  if (FALSE.has(low)) return false;
  throw new Error(`env ${name}=${JSON.stringify(raw)} is not a valid boolean`);
}

export function require_(name: string): string {
  const v = process.env[name];
  if (v === undefined || v === '') throw new MissingEnvError(name);
  return v;
}
