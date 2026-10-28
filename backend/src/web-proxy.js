import { existsSync } from 'node:fs';
import { request as httpRequest } from 'node:http';
import { request as httpsRequest } from 'node:https';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const webDirectory = path.resolve(currentDirectory, '../../build/web');
const indexPath = path.join(webDirectory, 'index.html');
const port = Number(process.env.WEB_PORT ?? 8765);
const apiOrigin = new URL(process.env.API_ORIGIN ?? 'http://127.0.0.1:3000');

if (!existsSync(indexPath)) {
  throw new Error('Flutter web build not found. Run `flutter build web` first.');
}

const app = express();

app.use('/api', (request, response) => {
  const requestUpstream = apiOrigin.protocol === 'https:'
    ? httpsRequest
    : httpRequest;
  const upstream = requestUpstream(
    new URL(request.originalUrl, apiOrigin),
    {
      method: request.method,
      headers: { ...request.headers, host: apiOrigin.host },
    },
    (apiResponse) => {
      response.writeHead(
        apiResponse.statusCode ?? 502,
        apiResponse.headers,
      );
      apiResponse.pipe(response);
    },
  );

  upstream.on('error', (error) => {
    console.error(`PetVault API proxy failed: ${error.message}`);
    if (!response.headersSent) {
      response.status(502).json({ error: 'PetVault API is unavailable.' });
    } else {
      response.destroy(error);
    }
  });

  request.pipe(upstream);
});

app.use(express.static(webDirectory));
app.use((request, response, next) => {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    next();
    return;
  }
  response.sendFile(indexPath, (error) => {
    if (error) next(error);
  });
});
app.use((error, _request, response, _next) => {
  console.error(`PetVault web server failed: ${error.message}`);
  if (!response.headersSent) {
    response.status(500).send('PetVault web server error.');
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(
    `PetVault web app listening on port ${port}; API proxy: ${apiOrigin.origin}`,
  );
});
