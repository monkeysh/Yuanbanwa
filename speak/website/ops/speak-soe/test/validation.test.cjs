'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { HttpError, TokenBucketStore, loadConfig, normalizeResult, parsePayload } = require('../server.js');

const config = loadConfig({
  SOE_APP_ID: 'test-app',
  SOE_SECRET_ID: 'test-secret-id',
  SOE_SECRET_KEY: 'test-secret-key',
  SOE_SIGNING_SECRET: 'validation-test-secret-longer-than-thirty-two-bytes',
  ALLOW_ORIGINS: 'https://speak.yuanbanwa.top',
  SOE_MIN_PCM_BYTES: '3200',
  SOE_MAX_PCM_BYTES: '3202',
  SOE_MAX_BODY_BYTES: '16384',
});

test('payload validation accepts strict even-byte PCM16', () => {
  const body = Buffer.from(JSON.stringify({
    refText: 'Hello.',
    voiceData: Buffer.alloc(3200).toString('base64'),
  }));
  const parsed = parsePayload(body, config);
  assert.equal(parsed.refText, 'Hello.');
  assert.equal(parsed.pcm.length, 3200);
});

test('payload validation rejects non-canonical base64', () => {
  const body = Buffer.from(JSON.stringify({ refText: 'Hello.', voiceData: 'AAAA\nAA==' }));
  assert.throws(
    () => parsePayload(body, config),
    error => error instanceof HttpError && error.code === 'invalid_base64',
  );
});

test('token bucket enforces its configured burst', () => {
  const store = new TokenBucketStore(2, 60000);
  assert.equal(store.consume('user', 1000).allowed, true);
  assert.equal(store.consume('user', 1000).allowed, true);
  const rejected = store.consume('user', 1000);
  assert.equal(rejected.allowed, false);
  assert.equal(rejected.retryAfter, 30);
});

test('normalization tolerates malformed word entries without exposing raw data', () => {
  const normalized = normalizeResult({ Words: [null, { Word: 'Hello', PhoneInfo: [null] }] }, false);
  assert.equal(normalized.parsed, true);
  assert.equal(normalized.words.length, 2);
  assert.equal(normalized.words[1].word, 'Hello');
  assert.equal(normalized.raw, undefined);
});
