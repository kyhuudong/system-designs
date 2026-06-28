// Recipe: /health and /ready HTTP handlers, stdlib only
// Stdlib-only (node:http).
// Usage:
//   import { createHealthServer, setReady } from './healthcheck.js';
//   const server = createHealthServer();
//   server.listen(8080);
//   setReady(true);
//
// /health  -> 200 {"status":"ok"} always
// /ready   -> 200 {"status":"ready"} or 503 {"status":"not_ready"}

import { createServer, type Server } from 'node:http';

let ready = false;

export function setReady(value: boolean): void {
  ready = Boolean(value);
}

export function createHealthServer(): Server {
  return createServer((req, res) => {
    const send = (status: number, payload: Record<string, unknown>): void => {
      const body = JSON.stringify(payload);
      res.writeHead(status, {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      });
      res.end(body);
    };

    if (req.url === '/health') {
      send(200, { status: 'ok' });
    } else if (req.url === '/ready') {
      if (ready) send(200, { status: 'ready' });
      else send(503, { status: 'not_ready' });
    } else {
      send(404, { status: 'not_found', path: req.url });
    }
  });
}
