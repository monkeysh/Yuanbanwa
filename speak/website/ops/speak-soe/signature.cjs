'use strict';

const crypto = require('crypto');

const SIGNATURE_VERSION = 'soe-v1';
const DEFAULT_PATH = '/api/soe';
const USER_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_.:@-]{0,63}$/;
const NONCE_PATTERN = /^[A-Za-z0-9_-]{16,64}$/;

class SignatureError extends Error {
  constructor(code) {
    super(code);
    this.name = 'SignatureError';
    this.code = code;
  }
}

function toBodyBuffer(body) {
  if (Buffer.isBuffer(body)) return body;
  if (typeof body === 'string') return Buffer.from(body, 'utf8');
  throw new TypeError('body must be a string or Buffer');
}

function assertSecret(secret) {
  if (typeof secret !== 'string' || Buffer.byteLength(secret, 'utf8') < 32) {
    throw new TypeError('signing secret must be at least 32 bytes');
  }
}

function buildCanonicalRequest({ body, userId, timestamp, nonce, method = 'POST', pathname = DEFAULT_PATH }) {
  if (!USER_ID_PATTERN.test(userId || '')) throw new TypeError('invalid userId');
  if (!Number.isSafeInteger(Number(timestamp)) || Number(timestamp) <= 0) throw new TypeError('invalid timestamp');
  if (!NONCE_PATTERN.test(nonce || '')) throw new TypeError('invalid nonce');
  if (!/^\/[A-Za-z0-9/_-]*$/.test(pathname || '')) throw new TypeError('invalid pathname');

  const bodyHash = crypto.createHash('sha256').update(toBodyBuffer(body)).digest('hex');
  return [
    SIGNATURE_VERSION,
    String(timestamp),
    nonce,
    userId,
    String(method).toUpperCase(),
    pathname,
    bodyHash,
  ].join('\n');
}

function createSignedHeaders({
  body,
  userId,
  secret,
  timestamp = Math.floor(Date.now() / 1000),
  nonce = crypto.randomBytes(18).toString('base64url'),
  method = 'POST',
  pathname = DEFAULT_PATH,
}) {
  assertSecret(secret);
  const canonical = buildCanonicalRequest({ body, userId, timestamp, nonce, method, pathname });
  const digest = crypto.createHmac('sha256', secret).update(canonical).digest('hex');

  return {
    'Content-Type': 'application/json',
    'X-SOE-User': userId,
    'X-SOE-Timestamp': String(timestamp),
    'X-SOE-Nonce': nonce,
    'X-SOE-Signature': `v1=${digest}`,
  };
}

function readHeader(headers, name) {
  const wanted = String(name).toLowerCase();
  const matchedName = Object.keys(headers || {}).find(key => key.toLowerCase() === wanted);
  const value = matchedName === undefined ? undefined : headers[matchedName];
  return Array.isArray(value) ? value[0] : value;
}

function verifySignedHeaders({
  body,
  headers,
  secret,
  nowSeconds = Math.floor(Date.now() / 1000),
  maxClockSkewSeconds = 60,
  method = 'POST',
  pathname = DEFAULT_PATH,
}) {
  assertSecret(secret);

  const userId = readHeader(headers, 'x-soe-user');
  const timestampText = readHeader(headers, 'x-soe-timestamp');
  const nonce = readHeader(headers, 'x-soe-nonce');
  const signatureText = readHeader(headers, 'x-soe-signature');

  if (!USER_ID_PATTERN.test(userId || '')) throw new SignatureError('invalid_user');
  if (!/^\d{10,13}$/.test(timestampText || '')) throw new SignatureError('invalid_timestamp');
  const timestamp = Number(timestampText);
  if (!Number.isSafeInteger(timestamp)) throw new SignatureError('invalid_timestamp');
  if (Math.abs(nowSeconds - timestamp) > maxClockSkewSeconds) throw new SignatureError('expired_timestamp');
  if (!NONCE_PATTERN.test(nonce || '')) throw new SignatureError('invalid_nonce');

  const match = /^v1=([a-f0-9]{64})$/i.exec(signatureText || '');
  if (!match) throw new SignatureError('invalid_signature');

  const canonical = buildCanonicalRequest({ body, userId, timestamp, nonce, method, pathname });
  const expected = crypto.createHmac('sha256', secret).update(canonical).digest();
  const received = Buffer.from(match[1], 'hex');
  if (received.length !== expected.length || !crypto.timingSafeEqual(received, expected)) {
    throw new SignatureError('invalid_signature');
  }

  return { userId, timestamp, nonce };
}

module.exports = {
  DEFAULT_PATH,
  SIGNATURE_VERSION,
  SignatureError,
  buildCanonicalRequest,
  createSignedHeaders,
  verifySignedHeaders,
};
