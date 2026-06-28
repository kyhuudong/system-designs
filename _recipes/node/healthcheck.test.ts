import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';
import { createHealthServer, setReady } from './healthcheck.js';

async function get(port: number, path: string): Promise<{ status: number; body: unknown }> {
  const res = await fetch(`http://127.0.0.1:${port}${path}`);
  const body = await res.json();
  return { status: res.status, body };
}

describe('healthcheck', () => {
  let server: Server;
  let port: number;

  beforeAll(async () => {
    server = createHealthServer();
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    port = (server.address() as AddressInfo).port;
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve())),
    );
  });

  it('/health is always 200', async () => {
    const { status, body } = await get(port, '/health');
    expect(status).toBe(200);
    expect(body).toEqual({ status: 'ok' });
  });

  it('/ready is 503 until setReady(true)', async () => {
    setReady(false);
    let res = await get(port, '/ready');
    expect(res.status).toBe(503);
    expect(res.body).toEqual({ status: 'not_ready' });

    setReady(true);
    res = await get(port, '/ready');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ready' });
  });

  it('unknown path returns 404', async () => {
    const { status } = await get(port, '/nope');
    expect(status).toBe(404);
  });
});
