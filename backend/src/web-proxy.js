import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import https from 'node:https';
import { fileURLToPath } from 'node:url';
import { loadConfig } from './config.js';

const config = loadConfig();
const root = path.resolve(
  config.webRoot ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../build/web'),
);
const apiOrigin = new URL(config.apiOrigin);

function proxyApi(req, res) {
  const transport = apiOrigin.protocol === 'https:' ? https : http;
  const request = transport.request(
    new URL(req.url, apiOrigin),
    {
      method: req.method,
      headers: {
        ...req.headers,
        host: apiOrigin.host,
      },
    },
    (response) => {
      res.writeHead(response.statusCode ?? 502, response.headers);
      response.pipe(res);
    },
  );
  request.on('error', () => {
    if (!res.headersSent) {
      res.writeHead(502, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: 'The API service is unavailable.' }));
    } else {
      res.destroy();
    }
  });
  req.pipe(request);
}

function serveStatic(req, res) {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  const requested = path.resolve(root, `.${decodeURIComponent(pathname)}`);
  if (requested !== root && !requested.startsWith(`${root}${path.sep}`)) {
    res.writeHead(400).end('Invalid path');
    return;
  }
  const file = fs.existsSync(requested) && fs.statSync(requested).isFile()
    ? requested
    : path.join(root, 'index.html');
  if (!fs.existsSync(file)) {
    res.writeHead(503, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('Build the Flutter web application before starting the web proxy.');
    return;
  }
  const types = {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.js': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.wasm': 'application/wasm',
  };
  res.writeHead(200, {
    'content-type': types[path.extname(file)] ?? 'application/octet-stream',
    'x-content-type-options': 'nosniff',
  });
  fs.createReadStream(file).pipe(res);
}

http.createServer((req, res) => {
  if (req.url === '/api' || req.url?.startsWith('/api/')) {
    proxyApi(req, res);
  } else {
    serveStatic(req, res);
  }
}).listen(config.webPort, '0.0.0.0', () => {
  console.info('web_proxy_started', { port: config.webPort });
});
