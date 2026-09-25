// 给新 KET 场景烧音频:每句烧 rosie(女声),男声轮(audio.chris 存在)额外烧 chris。
// 直接按句子 audio map 里的路径烧到 audio/rosie|chris/,幂等(已存在>1KB 跳过)。
// 用法: node burn_ket_audio.mjs ket-family ket-daily ...   (需指定场景 id)
import { readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from 'node:fs';
import { dirname } from 'node:path';

const VENV = '/Users/gelili/Documents/Claude.English/yuanbanwa-vocab/.env';
const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const SCENES = `${ROOT}/scenes.json`;
// chris voice id 来自 Speak-ios/scripts/elevenlabs-generate.py 的 VOICES 映射(旧四声线男声)。
const CHRIS_VOICE = 'iP95p4xoKVk53GoZ742B';

function readEnv(p) {
  let key, rosie;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const t = line.trim();
    if (t.startsWith('ELEVENLABS_API_KEY=')) key = t.slice(19).replace(/^"|"$/g, '');
    else if (t.startsWith('ELEVENLABS_VOICE_ID=')) rosie = t.slice(20).replace(/^"|"$/g, '');
  }
  return { key, rosie };
}
const { key, rosie } = readEnv(VENV);
if (!key || !rosie) { console.error('未读到 ELEVENLABS_API_KEY / VOICE_ID'); process.exit(1); }

const sleep = ms => new Promise(r => setTimeout(r, ms));
async function tts(text, voiceId, outPath) {
  if (existsSync(outPath) && statSync(outPath).size > 1000) return 'skip';
  const ctrl = new AbortController();
  const to = setTimeout(() => ctrl.abort(), 60000);
  try {
    const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
      method: 'POST', signal: ctrl.signal,
      headers: { 'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg' },
      body: JSON.stringify({ text, model_id: 'eleven_multilingual_v2',
        voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.0, use_speaker_boost: true } }),
    });
    if (!r.ok) { console.error('  HTTP', r.status, (await r.text()).slice(0, 160)); return 'fail'; }
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 1000) { console.error('  too small', buf.length); return 'fail'; }
    mkdirSync(dirname(outPath), { recursive: true });
    writeFileSync(outPath, buf);
    return 'ok';
  } catch (e) { console.error('  err', e.message); return 'fail'; }
  finally { clearTimeout(to); }
}

const all = JSON.parse(readFileSync(SCENES, 'utf8'));
const ids = process.argv.slice(2);
if (!ids.length) { console.error('未指定场景 id'); process.exit(1); }

let n = 0, ok = 0, skip = 0, fail = 0;
for (const id of ids) {
  const sc = all.scenes.find(s => s.id === id);
  if (!sc) { console.error('找不到', id); continue; }
  const sents = (sc.tiers || []).flatMap(t => t.sentences || []);
  console.log(`\n● ${id} (${sents.length} 句)`);
  for (const s of sents) {
    const au = s.audio || {};
    // 每句烧 rosie
    for (const [voiceKey, rel] of [['rosie', au.rosie], ['chris', au.chris]]) {
      if (!rel) continue;
      const voiceId = voiceKey === 'chris' ? CHRIS_VOICE : rosie;
      n++;
      const res = await tts(s.en, voiceId, `${ROOT}/audio/${rel}`);
      if (res === 'ok') ok++; else if (res === 'skip') skip++; else fail++;
      process.stdout.write(`  ${voiceKey.padEnd(5)} ${res.padEnd(4)} ${rel}\n`);
      if (res === 'ok') await sleep(250);
    }
  }
}
console.log(`\n=== 完成: 音频数 ${n} | 新烧 ${ok} | 跳过 ${skip} | 失败 ${fail} ===`);
