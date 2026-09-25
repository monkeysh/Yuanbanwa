'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { SignatureError, createSignedHeaders, verifySignedHeaders } = require('../signature.cjs');

const secret = 'test-only-signing-secret-that-is-longer-than-32-bytes';
const timestamp = 1783737600;
const nonce = 'abcdefghijklmnopQRSTUVWX';
const userId = 'student_123';
const body = JSON.stringify({ refText: 'Hello.', voiceData: 'AAAAAA==' });

test('a canonical request signature verifies', () => {
  const headers = createSignedHeaders({ body, userId, secret, timestamp, nonce });
  const verified = verifySignedHeaders({
    body,
    headers,
    secret,
    nowSeconds: timestamp,
  });
  assert.deepEqual(verified, { userId, timestamp, nonce });
});

test('body tampering invalidates the signature', () => {
  const headers = createSignedHeaders({ body, userId, secret, timestamp, nonce });
  assert.throws(
    () => verifySignedHeaders({
      body: `${body} `,
      headers,
      secret,
      nowSeconds: timestamp,
    }),
    error => error instanceof SignatureError && error.code === 'invalid_signature',
  );
});

test('stale signatures are rejected', () => {
  const headers = createSignedHeaders({ body, userId, secret, timestamp, nonce });
  assert.throws(
    () => verifySignedHeaders({
      body,
      headers,
      secret,
      nowSeconds: timestamp + 61,
      maxClockSkewSeconds: 60,
    }),
    error => error instanceof SignatureError && error.code === 'expired_timestamp',
  );
});
