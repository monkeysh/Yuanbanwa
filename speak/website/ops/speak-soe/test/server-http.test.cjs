'use strict';

const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');
const { createSignedHeaders } = require('../signature.cjs');
const { createService, loadConfig } = require('../server.js');

const signingSecret = 'local-http-test-signing-secret-longer-than-32-bytes';
const config = loadConfig({
  SOE_APP_ID: 'test-app',
  SOE_SECRET_ID: 'test-secret-id',
  SOE_SECRET_KEY: 'test-secret-key',
  SOE_SIGNING_SECRET: signingSecret,
  ALLOW_ORIGINS: 'https://speak.yuanbanwa.top',
  SOE_IP_RATE_LIMIT: '20',
  SOE_USER_RATE_LIMIT: '10',
});

function request(port, { path = '/api/soe', method = 'GET', body = '', headers = {} } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      host: '127.0.0.1',
      port,
      path,
      method,
      headers: {
        ...headers,
        ...(body ? { 'Content-Length': Buffer.byteLength(body) } : {}),
      },
    }, res => {
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve({
        status: res.statusCode,
        headers: res.headers,
        json: chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : null,
      }));
    });
    req.on('error', reject);
    req.end(body);
  });
}

test('HTTP boundary exposes only health and requires a valid request signature', async () => {
  const service = createService(config);
  await new Promise((resolve, reject) => {
    service.server.once('error', reject);
    service.server.listen(0, '127.0.0.1', resolve);
  });
  const port = service.server.address().port;

  try {
    const health = await request(port, { path: '/api/soe/healthz' });
    assert.equal(health.status, 200);
    assert.equal(health.json.ok, true);
    assert.equal(health.json.hasKey, undefined);

    const body = JSON.stringify({ refText: 'Hello.', voiceData: 'AAAAAA==' });
    const unsigned = await request(port, {
      method: 'POST',
      body,
      headers: { 'Content-Type': 'application/json' },
    });
    assert.equal(unsigned.status, 401);
    assert.equal(unsigned.json.code, 'invalid_signature');

    const signedHeaders = createSignedHeaders({ body, userId: 'test_user', secret: signingSecret });
    const signed = await request(port, { method: 'POST', body, headers: signedHeaders });
    assert.equal(signed.status, 400);
    assert.equal(signed.json.code, 'audio_too_short');

    const disallowedOrigin = await request(port, {
      method: 'OPTIONS',
      headers: { Origin: 'https://attacker.example' },
    });
    assert.equal(disallowedOrigin.status, 403);
    assert.equal(disallowedOrigin.headers['access-control-allow-origin'], undefined);
  } finally {
    await service.shutdown();
  }
});
