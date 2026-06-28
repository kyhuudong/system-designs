import { createServer } from 'node:http';

const port = Number(process.env.PORT ?? 3000);

const server = createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: '__PROJECT_NAME__', status: 'ok' }));
});

server.listen(port, () => {
  console.log(`__PROJECT_NAME__ listening on http://localhost:${port}`);
});

export { server };
