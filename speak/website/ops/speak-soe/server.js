'use strict';

// Hardened Speak pronunciation assessment proxy.
// Public contract remains POST { refText, voiceData }, where voiceData is
// 16 kHz mono signed PCM16 (little-endian) encoded as strict base64.

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const net = require('net');
const path = require('path');
const { TextDecoder } = require('util');
const WebSocket = require('ws');
const { DEFAULT_PATH, SignatureError, verifySignedHeaders } = require('./signature.cjs');

const SERVICE_VERSION = '3.0.0';
const HEALTH_PATH = `${DEFAULT_PATH}/healthz`;
const JSON_DECODER = new TextDecoder('utf-8', { fatal: true });

function loadEnvFile(filename) {
  let contents;
  try {
    contents = fs.readFileSync(filename, 'utf8');
  } catch (error) {
    if (error && error.code === 'ENOENT') return;
    throw error;
  }

  for (const line of contents.split(/\r?\n/)) {
    const match = /^\s*(?:export\s+)?([A-Z][A-Z0-9_]*)\s*=\s*(.*)\s*$/.exec(line);
    if (!match || process.env[match[1]] !== undefined) continue;
    let value = match[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    process.env[match[1]] = value;
  }
}

function envInteger(env, name, fallback, min, max) {
  const raw = env[name];
  const value = raw === undefined || raw === '' ? fallback : Number(raw);
  if (!Number.isSafeInteger(value) || value < min || value > max) {
    throw new Error(`${name} must be an integer between ${min} and ${max}`);
  }
  return value;
}

function envNumber(env, name, fallback, min, max) {
  const raw = env[name];
  const value = raw === undefined || raw === '' ? fallback : Number(raw);
  if (!Number.isFinite(value) || value < min || value > max) {
    throw new Error(`${name} must be a number between ${min} and ${max}`);
  }
  return value;
}

function envBoolean(env, name, fallback = false) {
  const raw = env[name];
  if (raw === undefined || raw === '') return fallback;
  if (/^(1|true|yes)$/i.test(raw)) return true;
  if (/^(0|false|no)$/i.test(raw)) return false;
  throw new Error(`${name} must be true or false`);
}

function parseOrigins(raw) {
  const origins = new Set(String(raw || '').split(',').map(value => value.trim()).filter(Boolean));
  if (origins.size === 0) throw new Error('ALLOW_ORIGINS must contain at least one origin');
  for (const origin of origins) {
    let parsed;
    try {
      parsed = new URL(origin);
    } catch {
      throw new Error(`ALLOW_ORIGINS contains an invalid origin: ${origin}`);
    }
    if (!['http:', 'https:'].includes(parsed.protocol) || parsed.origin !== origin) {
      throw new Error(`ALLOW_ORIGINS must contain exact HTTP(S) origins without paths: ${origin}`);
    }
  }
  return origins;
}

function loadConfig(env = process.env) {
  const maxPcmBytes = envInteger(env, 'SOE_MAX_PCM_BYTES', 960000, 3200, 2000000);
  const maxBodyBytes = envInteger(env, 'SOE_MAX_BODY_BYTES', 1400000, 16384, 3000000);
  return Object.freeze({
    appId: env.SOE_APP_ID || '',
    secretId: env.SOE_SECRET_ID || '',
    secretKey: env.SOE_SECRET_KEY || '',
    signingSecret: env.SOE_SIGNING_SECRET || '',
    engine: env.SOE_ENGINE || '16k_en',
    scoreCoeff: envNumber(env, 'SOE_SCORE_COEFF', 1, 1, 4),
    port: envInteger(env, 'PORT', 4006, 1024, 65535),
    allowedOrigins: parseOrigins(env.ALLOW_ORIGINS || env.ALLOW_ORIGIN || 'https://speak.yuanbanwa.top'),
    authClockSkewSeconds: envInteger(env, 'SOE_AUTH_CLOCK_SKEW_SECONDS', 60, 10, 300),
    maxBodyBytes,
    maxPcmBytes,
    minPcmBytes: envInteger(env, 'SOE_MIN_PCM_BYTES', 3200, 2, maxPcmBytes),
    maxRefChars: envInteger(env, 'SOE_MAX_REF_CHARS', 500, 1, 2000),
    maxRefBytes: envInteger(env, 'SOE_MAX_REF_BYTES', 2000, 1, 8000),
    requestBodyTimeoutMs: envInteger(env, 'SOE_REQUEST_BODY_TIMEOUT_MS', 10000, 1000, 30000),
    upstreamTimeoutMs: envInteger(env, 'SOE_UPSTREAM_TIMEOUT_MS', 25000, 3000, 60000),
    upstreamHandshakeTimeoutMs: envInteger(env, 'SOE_UPSTREAM_HANDSHAKE_TIMEOUT_MS', 5000, 1000, 15000),
    upstreamMaxPayloadBytes: envInteger(env, 'SOE_UPSTREAM_MAX_PAYLOAD_BYTES', 2000000, 65536, 5000000),
    upstreamUrlTtlSeconds: envInteger(env, 'SOE_UPSTREAM_URL_TTL_SECONDS', 60, 30, 300),
    rateWindowMs: envInteger(env, 'SOE_RATE_WINDOW_MS', 60000, 1000, 3600000),
    ipRateLimit: envInteger(env, 'SOE_IP_RATE_LIMIT', 20, 1, 1000),
    userRateLimit: envInteger(env, 'SOE_USER_RATE_LIMIT', 10, 1, 1000),
    globalConcurrency: envInteger(env, 'SOE_GLOBAL_CONCURRENCY', 4, 1, 64),
    ipConcurrency: envInteger(env, 'SOE_IP_CONCURRENCY', 2, 1, 16),
    userConcurrency: envInteger(env, 'SOE_USER_CONCURRENCY', 1, 1, 8),
    includeRawResult: envBoolean(env, 'SOE_INCLUDE_RAW_RESULT', false),
  });
}

function validateConfig(config) {
  const missing = [];
  if (!config.appId) missing.push('SOE_APP_ID');
  if (!config.secretId) missing.push('SOE_SECRET_ID');
  if (!config.secretKey) missing.push('SOE_SECRET_KEY');
  if (!config.signingSecret) missing.push('SOE_SIGNING_SECRET');
  if (missing.length) throw new Error(`missing required environment variables: ${missing.join(', ')}`);
  if (Buffer.byteLength(config.signingSecret, 'utf8') < 32) {
    throw new Error('SOE_SIGNING_SECRET must be at least 32 bytes');
  }
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(config.engine)) throw new Error('SOE_ENGINE has an invalid format');
  const maxEncodedAudioBytes = Math.ceil(config.maxPcmBytes / 3) * 4;
  if (config.maxBodyBytes < maxEncodedAudioBytes + 256) {
    throw new Error('SOE_MAX_BODY_BYTES is too small for SOE_MAX_PCM_BYTES');
  }
  if (config.userConcurrency > config.ipConcurrency || config.ipConcurrency > config.globalConcurrency) {
    throw new Error('concurrency limits must satisfy user <= IP <= global');
  }
}

class HttpError extends Error {
  constructor(status, code, publicMessage, options = {}) {
    super(code);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
    this.publicMessage = publicMessage;
    this.retryAfter = options.retryAfter;
  }
}

class SoeUpstreamError extends Error {
  constructor(code, vendorCode) {
    super(code);
    this.name = 'SoeUpstreamError';
    this.code = code;
    this.vendorCode = vendorCode;
  }
}

class TokenBucketStore {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.buckets = new Map();
  }

  consume(key, now = Date.now()) {
    const previous = this.buckets.get(key);
    const bucket = previous || { tokens: this.limit, updatedAt: now, lastSeenAt: now };
    const elapsed = Math.max(0, now - bucket.updatedAt);
    bucket.tokens = Math.min(this.limit, bucket.tokens + (elapsed * this.limit / this.windowMs));
    bucket.updatedAt = now;
    bucket.lastSeenAt = now;

    if (bucket.tokens < 1) {
      this.buckets.set(key, bucket);
      const waitMs = Math.ceil((1 - bucket.tokens) * this.windowMs / this.limit);
      return { allowed: false, retryAfter: Math.max(1, Math.ceil(waitMs / 1000)) };
    }

    bucket.tokens -= 1;
    this.buckets.set(key, bucket);
    return { allowed: true, retryAfter: 0 };
  }

  prune(now = Date.now()) {
    const staleAfter = this.windowMs * 2;
    for (const [key, bucket] of this.buckets) {
      if (now - bucket.lastSeenAt > staleAfter) this.buckets.delete(key);
    }
  }
}

function createConcurrencyGate(config) {
  let globalActive = 0;
  const byIp = new Map();
  const byUser = new Map();

  function acquire(ip, userId) {
    if (globalActive >= config.globalConcurrency ||
        (byIp.get(ip) || 0) >= config.ipConcurrency ||
        (byUser.get(userId) || 0) >= config.userConcurrency) {
      throw new HttpError(429, 'concurrency_limited', '当前评测请求较多，请稍后再试', { retryAfter: 1 });
    }

    globalActive += 1;
    byIp.set(ip, (byIp.get(ip) || 0) + 1);
    byUser.set(userId, (byUser.get(userId) || 0) + 1);
    let released = false;

    return () => {
      if (released) return;
      released = true;
      globalActive -= 1;
      decrement(byIp, ip);
      decrement(byUser, userId);
    };
  }

  return { acquire };
}

function decrement(map, key) {
  const next = (map.get(key) || 1) - 1;
  if (next <= 0) map.delete(key);
  else map.set(key, next);
}

function normalizeIp(value) {
  if (typeof value !== 'string') return '';
  const candidate = value.startsWith('::ffff:') ? value.slice(7) : value;
  return net.isIP(candidate) ? candidate : '';
}

function isLoopback(value) {
  const ip = normalizeIp(value);
  return ip === '127.0.0.1' || ip === '::1';
}

function getClientIp(req) {
  const remote = normalizeIp(req.socket.remoteAddress) || 'unknown';
  if (!isLoopback(remote)) return remote;
  const forwarded = normalizeIp(req.headers['x-real-ip']);
  return forwarded || remote;
}

function buildSoeUrl(config, refText) {
  const now = Math.floor(Date.now() / 1000);
  const params = {
    eval_mode: 1,
    expired: now + config.upstreamUrlTtlSeconds,
    nonce: crypto.randomInt(1, 2147483647),
    ref_text: refText,
    rec_mode: 1,
    score_coeff: config.scoreCoeff,
    secretid: config.secretId,
    server_engine_type: config.engine,
    timestamp: now,
    voice_format: 0,
    voice_id: crypto.randomUUID(),
  };
  const keys = Object.keys(params).sort();
  const signText = `soe.cloud.tencent.com/soe/api/${config.appId}?${keys.map(key => `${key}=${params[key]}`).join('&')}`;
  const signature = crypto.createHmac('sha1', config.secretKey).update(signText).digest('base64');
  const query = keys.map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`).join('&');
  return `wss://soe.cloud.tencent.com/soe/api/${config.appId}?${query}&signature=${encodeURIComponent(signature)}`;
}

function callSoe(config, refText, pcm, signal) {
  return new Promise((resolve, reject) => {
    let ws;
    let lastResult = null;
    let settled = false;

    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      signal.removeEventListener('abort', onAbort);
      if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
        try { ws.terminate(); } catch { /* no-op */ }
      }
      callback(value);
    };

    const onAbort = () => finish(reject, new SoeUpstreamError('client_aborted'));
    const timeout = setTimeout(
      () => finish(reject, new SoeUpstreamError('upstream_timeout')),
      config.upstreamTimeoutMs,
    );
    timeout.unref();
    signal.addEventListener('abort', onAbort, { once: true });
    if (signal.aborted) return onAbort();

    try {
      ws = new WebSocket(buildSoeUrl(config, refText), {
        followRedirects: false,
        handshakeTimeout: config.upstreamHandshakeTimeoutMs,
        maxPayload: config.upstreamMaxPayloadBytes,
        perMessageDeflate: false,
      });
    } catch {
      return finish(reject, new SoeUpstreamError('upstream_connect_failed'));
    }

    ws.once('open', () => {
      ws.send(pcm, { binary: true }, error => {
        if (error) return finish(reject, new SoeUpstreamError('upstream_send_failed'));
        ws.send(JSON.stringify({ type: 'end' }), error2 => {
          if (error2) finish(reject, new SoeUpstreamError('upstream_send_failed'));
        });
      });
    });

    ws.on('message', data => {
      let message;
      try {
        message = JSON.parse(data.toString('utf8'));
      } catch {
        return;
      }
      if (!message || typeof message !== 'object' || Array.isArray(message)) return;
      if (typeof message.code === 'number' && message.code !== 0) {
        return finish(reject, new SoeUpstreamError('upstream_rejected', message.code));
      }
      if (message.result !== null && message.result !== undefined && message.result !== '') {
        lastResult = message.result;
      }
      if (message.final === 1) {
        if (lastResult === null) return finish(reject, new SoeUpstreamError('upstream_empty_result'));
        return finish(resolve, lastResult);
      }
    });

    ws.once('unexpected-response', (_request, response) => {
      finish(reject, new SoeUpstreamError('upstream_http_error', response && response.statusCode));
    });
    ws.once('error', () => finish(reject, new SoeUpstreamError('upstream_socket_error')));
    ws.once('close', () => {
      if (lastResult !== null) finish(resolve, lastResult);
      else finish(reject, new SoeUpstreamError('upstream_closed_without_result'));
    });
  });
}

function finiteNumber(value) {
  if (value === null || value === undefined || value === '' || typeof value === 'boolean') return undefined;
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function normalizeResult(raw, includeRawResult) {
  if (raw === null || raw === undefined) return { parsed: false };
  let object = raw;
  if (typeof raw === 'string') {
    try {
      object = JSON.parse(raw);
    } catch {
      return includeRawResult ? { parsed: false, raw } : { parsed: false };
    }
  }
  if (!object || typeof object !== 'object' || Array.isArray(object)) {
    return includeRawResult ? { parsed: false, raw } : { parsed: false };
  }

  const normalized = {
    parsed: true,
    suggestedScore: finiteNumber(object.SuggestedScore),
    pronAccuracy: finiteNumber(object.PronAccuracy),
    pronFluency: finiteNumber(object.PronFluency),
    pronCompletion: finiteNumber(object.PronCompletion),
    words: (Array.isArray(object.Words) ? object.Words : []).slice(0, 500).map(word => ({
      word: word && typeof word.Word === 'string' ? word.Word : '',
      accuracy: finiteNumber(word && word.PronAccuracy),
      phones: (word && Array.isArray(word.PhoneInfo) ? word.PhoneInfo : word && Array.isArray(word.PhoneInfos) ? word.PhoneInfos : [])
        .slice(0, 32)
        .map(phone => ({
          phone: phone && typeof phone.Phone === 'string' ? phone.Phone : '',
          accuracy: finiteNumber(phone && phone.PronAccuracy),
        })),
    })),
  };
  if (includeRawResult) normalized.raw = raw;
  return normalized;
}

function parsePayload(body, config) {
  let text;
  try {
    text = JSON_DECODER.decode(body);
  } catch {
    throw new HttpError(400, 'invalid_utf8', '请求内容不是有效的 UTF-8');
  }

  let payload;
  try {
    payload = JSON.parse(text || '{}');
  } catch {
    throw new HttpError(400, 'invalid_json', '请求内容不是有效的 JSON');
  }
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new HttpError(400, 'invalid_payload', '请求格式不正确');
  }
  const unexpected = Object.keys(payload).filter(key => key !== 'refText' && key !== 'voiceData');
  if (unexpected.length) throw new HttpError(400, 'unexpected_fields', '请求包含不支持的字段');
  if (typeof payload.refText !== 'string' || typeof payload.voiceData !== 'string') {
    throw new HttpError(400, 'invalid_fields', 'refText 和 voiceData 必须是字符串');
  }

  const refText = payload.refText.trim();
  if (!refText) throw new HttpError(400, 'empty_ref_text', '参考文本不能为空');
  if (/\p{Cc}/u.test(refText)) throw new HttpError(400, 'invalid_ref_text', '参考文本包含无效控制字符');
  if (Array.from(refText).length > config.maxRefChars || Buffer.byteLength(refText, 'utf8') > config.maxRefBytes) {
    throw new HttpError(413, 'ref_text_too_large', '参考文本过长');
  }

  const voiceData = payload.voiceData;
  const maxBase64Length = Math.ceil(config.maxPcmBytes / 3) * 4;
  if (!voiceData || voiceData.length > maxBase64Length || voiceData.length % 4 !== 0 ||
      !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(voiceData)) {
    throw new HttpError(400, 'invalid_base64', 'voiceData 不是有效的 base64 PCM 音频');
  }

  const pcm = Buffer.from(voiceData, 'base64');
  const canonicalInput = voiceData.replace(/=+$/, '');
  const canonicalDecoded = pcm.toString('base64').replace(/=+$/, '');
  if (canonicalInput !== canonicalDecoded) {
    throw new HttpError(400, 'invalid_base64', 'voiceData 不是有效的 base64 PCM 音频');
  }
  if (pcm.length < config.minPcmBytes) throw new HttpError(400, 'audio_too_short', '录音时间过短');
  if (pcm.length > config.maxPcmBytes) throw new HttpError(413, 'audio_too_large', '录音时间过长');
  if (pcm.length % 2 !== 0) throw new HttpError(400, 'invalid_pcm', 'PCM16 音频字节数必须为偶数');

  return { refText, pcm };
}

function readBody(req, config) {
  const contentLengthHeader = req.headers['content-length'];
  if (contentLengthHeader !== undefined) {
    if (!/^\d+$/.test(contentLengthHeader)) {
      return Promise.reject(new HttpError(400, 'invalid_content_length', 'Content-Length 不正确'));
    }
    if (Number(contentLengthHeader) > config.maxBodyBytes) {
      return Promise.reject(new HttpError(413, 'body_too_large', '请求体过大'));
    }
  }

  return new Promise((resolve, reject) => {
    const chunks = [];
    let total = 0;
    let settled = false;

    const cleanup = () => {
      clearTimeout(timer);
      req.removeListener('data', onData);
      req.removeListener('end', onEnd);
      req.removeListener('error', onError);
      req.removeListener('aborted', onAborted);
    };
    const fail = error => {
      if (settled) return;
      settled = true;
      cleanup();
      req.resume();
      reject(error);
    };
    const onData = chunk => {
      total += chunk.length;
      if (total > config.maxBodyBytes) return fail(new HttpError(413, 'body_too_large', '请求体过大'));
      chunks.push(chunk);
    };
    const onEnd = () => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(Buffer.concat(chunks, total));
    };
    const onError = () => fail(new HttpError(400, 'body_read_failed', '读取请求体失败'));
    const onAborted = () => fail(new HttpError(408, 'request_aborted', '请求已中断'));
    const timer = setTimeout(
      () => fail(new HttpError(408, 'body_timeout', '上传录音超时')),
      config.requestBodyTimeoutMs,
    );
    timer.unref();

    req.on('data', onData);
    req.once('end', onEnd);
    req.once('error', onError);
    req.once('aborted', onAborted);
  });
}

function ensureAllowedOrigin(req, config) {
  const origin = req.headers.origin;
  if (origin === undefined) return undefined;
  if (typeof origin !== 'string' || !config.allowedOrigins.has(origin)) {
    throw new HttpError(403, 'origin_not_allowed', '请求来源不被允许');
  }
  return origin;
}

function responseHeaders(origin, requestId, extra = {}) {
  const headers = {
    'Cache-Control': 'no-store',
    'Content-Type': 'application/json; charset=utf-8',
    'X-Content-Type-Options': 'nosniff',
    'X-Request-Id': requestId,
    ...extra,
  };
  if (origin) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Expose-Headers'] = 'X-Request-Id, Retry-After';
    headers.Vary = 'Origin';
  }
  return headers;
}

function sendJson(res, status, payload, origin, requestId, extraHeaders = {}) {
  if (res.destroyed || res.writableEnded) return;
  const body = JSON.stringify(payload);
  res.writeHead(status, responseHeaders(origin, requestId, {
    'Content-Length': Buffer.byteLength(body),
    ...extraHeaders,
  }));
  res.end(body);
}

function consumeRateLimit(store, key, code) {
  const result = store.consume(key);
  if (!result.allowed) {
    throw new HttpError(429, code, '请求过于频繁，请稍后再试', { retryAfter: result.retryAfter });
  }
}

function mapError(error) {
  if (error instanceof HttpError) return error;
  if (error instanceof SignatureError) return new HttpError(401, 'invalid_signature', '评测请求未授权');
  if (error instanceof SoeUpstreamError) {
    if (error.code === 'client_aborted') return new HttpError(408, error.code, '请求已中断');
    if (error.code === 'upstream_timeout') return new HttpError(504, error.code, '评测服务响应超时，请稍后重试');
    return new HttpError(502, error.code, '发音评测暂时不可用，请稍后重试');
  }
  return new HttpError(500, 'internal_error', '服务器内部错误');
}

function auditHash(config, value) {
  return crypto.createHmac('sha256', config.signingSecret).update(String(value)).digest('hex').slice(0, 16);
}

function logEvent(event, fields = {}) {
  process.stdout.write(`${JSON.stringify({ timestamp: new Date().toISOString(), event, ...fields })}\n`);
}

function createService(config) {
  validateConfig(config);
  const ipRates = new TokenBucketStore(config.ipRateLimit, config.rateWindowMs);
  const userRates = new TokenBucketStore(config.userRateLimit, config.rateWindowMs);
  const concurrency = createConcurrencyGate(config);
  const replayNonces = new Map();
  const activeControllers = new Set();

  const cleanupTimer = setInterval(() => {
    const now = Date.now();
    ipRates.prune(now);
    userRates.prune(now);
    for (const [key, expiresAt] of replayNonces) {
      if (expiresAt <= now) replayNonces.delete(key);
    }
  }, Math.max(10000, config.rateWindowMs));
  cleanupTimer.unref();

  const handler = async (req, res) => {
    const requestId = crypto.randomUUID();
    const startedAt = Date.now();
    const clientIp = getClientIp(req);
    let url;
    let origin;
    let userId;
    let releaseConcurrency;
    const abortController = new AbortController();
    activeControllers.add(abortController);

    const abortOnDisconnect = () => {
      if (!res.writableFinished) abortController.abort();
    };
    req.once('aborted', abortOnDisconnect);
    res.once('close', abortOnDisconnect);

    try {
      try {
        url = new URL(req.url || '/', 'http://localhost');
      } catch {
        throw new HttpError(400, 'invalid_request_target', '请求路径不正确');
      }
      origin = ensureAllowedOrigin(req, config);

      if (url.search || url.hash) throw new HttpError(400, 'query_not_allowed', '该接口不接受查询参数');
      if (url.pathname === HEALTH_PATH) {
        if (req.method !== 'GET') throw new HttpError(405, 'method_not_allowed', '仅支持 GET');
        sendJson(res, 200, { ok: true, service: 'speak-soe', version: SERVICE_VERSION }, origin, requestId);
        return;
      }
      if (url.pathname !== DEFAULT_PATH) throw new HttpError(404, 'not_found', '接口不存在');

      if (req.method === 'OPTIONS') {
        const headers = responseHeaders(origin, requestId, {
          'Access-Control-Allow-Headers': 'Content-Type, X-SOE-User, X-SOE-Timestamp, X-SOE-Nonce, X-SOE-Signature',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Max-Age': '600',
        });
        delete headers['Content-Type'];
        res.writeHead(204, headers);
        res.end();
        return;
      }
      if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed', '仅支持 POST');

      const contentType = String(req.headers['content-type'] || '').split(';', 1)[0].trim().toLowerCase();
      if (contentType !== 'application/json') {
        throw new HttpError(415, 'unsupported_media_type', 'Content-Type 必须是 application/json');
      }

      const body = await readBody(req, config);
      consumeRateLimit(ipRates, clientIp, 'ip_rate_limited');

      const auth = verifySignedHeaders({
        body,
        headers: req.headers,
        secret: config.signingSecret,
        maxClockSkewSeconds: config.authClockSkewSeconds,
        method: req.method,
        pathname: url.pathname,
      });
      userId = auth.userId;

      const replayKey = crypto.createHash('sha256').update(`${auth.userId}\n${auth.nonce}`).digest('hex');
      if ((replayNonces.get(replayKey) || 0) > Date.now()) {
        throw new HttpError(401, 'replayed_request', '评测请求未授权');
      }
      replayNonces.set(replayKey, Date.now() + config.authClockSkewSeconds * 2000);
      consumeRateLimit(userRates, userId, 'user_rate_limited');

      const { refText, pcm } = parsePayload(body, config);
      releaseConcurrency = concurrency.acquire(clientIp, userId);
      const result = await callSoe(config, refText, pcm, abortController.signal);
      const normalized = normalizeResult(result, config.includeRawResult);
      sendJson(res, 200, normalized, origin, requestId);
      logEvent('assessment_completed', {
        requestId,
        durationMs: Date.now() - startedAt,
        pcmBytes: pcm.length,
        parsed: normalized.parsed,
        user: auditHash(config, userId),
        ip: auditHash(config, clientIp),
      });
    } catch (error) {
      const mapped = mapError(error);
      const extraHeaders = {};
      if (mapped.retryAfter) extraHeaders['Retry-After'] = String(mapped.retryAfter);
      if (mapped.status === 405) extraHeaders.Allow = url && url.pathname === HEALTH_PATH ? 'GET' : 'POST, OPTIONS';
      sendJson(res, mapped.status, { error: mapped.publicMessage, code: mapped.code }, origin, requestId, extraHeaders);
      logEvent('assessment_rejected', {
        requestId,
        durationMs: Date.now() - startedAt,
        status: mapped.status,
        code: mapped.code,
        vendorCode: error instanceof SoeUpstreamError ? error.vendorCode : undefined,
        user: userId ? auditHash(config, userId) : undefined,
        ip: auditHash(config, clientIp),
      });
    } finally {
      if (releaseConcurrency) releaseConcurrency();
      activeControllers.delete(abortController);
      req.removeListener('aborted', abortOnDisconnect);
      res.removeListener('close', abortOnDisconnect);
    }
  };

  const server = http.createServer(handler);
  server.requestTimeout = config.requestBodyTimeoutMs + 2000;
  server.headersTimeout = Math.min(10000, config.requestBodyTimeoutMs);
  server.keepAliveTimeout = 5000;
  server.maxRequestsPerSocket = 100;
  server.on('clientError', (_error, socket) => {
    if (socket.writable) socket.end('HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n');
  });

  return {
    server,
    shutdown() {
      clearInterval(cleanupTimer);
      for (const controller of activeControllers) controller.abort();
      return new Promise(resolve => server.close(resolve));
    },
  };
}

function main() {
  loadEnvFile(path.join(__dirname, '.env'));
  let config;
  try {
    config = loadConfig();
    validateConfig(config);
  } catch (error) {
    process.stderr.write(`[speak-soe] configuration error: ${error.message}\n`);
    process.exit(1);
  }

  const service = createService(config);
  service.server.once('error', error => {
    logEvent('server_error', { code: error && error.code ? error.code : 'unknown' });
    process.exit(1);
  });
  service.server.listen(config.port, '127.0.0.1', () => {
    logEvent('server_started', { version: SERVICE_VERSION, address: '127.0.0.1', port: config.port });
  });

  let stopping = false;
  const stop = signal => {
    if (stopping) return;
    stopping = true;
    logEvent('server_stopping', { signal });
    const forceExit = setTimeout(() => process.exit(1), 8000);
    forceExit.unref();
    service.shutdown().then(() => {
      clearTimeout(forceExit);
      process.exit(0);
    });
  };
  process.once('SIGTERM', () => stop('SIGTERM'));
  process.once('SIGINT', () => stop('SIGINT'));
}

function checkConfigOnly() {
  loadEnvFile(path.join(__dirname, '.env'));
  const config = loadConfig();
  validateConfig(config);
  logEvent('configuration_valid', { version: SERVICE_VERSION });
}

if (require.main === module) {
  if (process.argv.includes('--check-config')) {
    try {
      checkConfigOnly();
    } catch (error) {
      process.stderr.write(`[speak-soe] configuration error: ${error.message}\n`);
      process.exit(1);
    }
  } else {
    main();
  }
}

module.exports = {
  HttpError,
  TokenBucketStore,
  createService,
  checkConfigOnly,
  loadConfig,
  normalizeResult,
  parsePayload,
  validateConfig,
};
