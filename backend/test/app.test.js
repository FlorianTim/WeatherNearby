import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import { createApp } from '../src/app.js';

describe('backend app', () => {
  let server;
  let baseUrl;

  before(async () => {
    server = createApp().listen(0);
    await new Promise((resolve) => server.once('listening', resolve));
    baseUrl = `http://localhost:${server.address().port}`;
  });

  after(() => server.close());

  it('GET /health returns ok', async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok' });
  });

  it('GET /v1/config returns client-safe config', async () => {
    const res = await fetch(`${baseUrl}/v1/config`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { apiVersion: 'v1' });
  });

  it('POST /v1/echo validates the body with zod', async () => {
    const bad = await fetch(`${baseUrl}/v1/echo`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({}),
    });
    assert.equal(bad.status, 400);

    const ok = await fetch(`${baseUrl}/v1/echo`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ message: 'hello' }),
    });
    assert.equal(ok.status, 200);
    assert.deepEqual(await ok.json(), { message: 'hello' });
  });
});
