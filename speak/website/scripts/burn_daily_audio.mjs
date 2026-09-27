// 读 splice 产出的烧音频清单,给 daily 新句子烧 Rosie 音频 → audio/rosie/<base>.mp3。
// 复用 gen_rosie 的 ElevenLabs 参数(Rosie 声线,multilingual_v2)。已存在且>1KB 的跳过。
// 用法: node burn_daily_audio.mjs [burn.json]
import { readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from 'node:fs';

const VENV = '/Users/gelili/Documents/Claude.English/yuanbanwa-vocab/.env';
const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const ROSIE_DIR = `${ROOT}/audio/rosie`;
const BURN = process.argv[2] || `${ROOT}/_content-drafts/daily-expand-batch1-burn.json`;

function readEnv(p) {
  let key, voice;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const t = line.trim();
    if (t.startsWith('ELEVENLABS_API_KEY=')) key = t.slice(19).replace(/^"|"$/g, '');
    else if (t.startsWith('ELEVENLABS_VOICE_ID=')) voice = t.slice(20).replace(/^"|"$/g, '');
  }
  return { key, voice };
}
const { key, voice } = readEnv(VENV);
if (!key || !voice) { console.error('未读到 ELEVENLABS key/voice'); process.exit(1); }
if (!existsSync(ROSIE_DIR)) mkdirSync(ROSIE_DIR, { recursive: true });

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function tts(text, outPath) {
  if (existsSync(outPath) && statSync(outPath).size > 1000) return 'skip';
  const ctrl = new AbortController();
  const to = setTimeout(() => ctrl.abort(), 60000);
  try {
    const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}`, {
      method: 'POST', signal: ctrl.signal,
      headers: { 'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg' },
      body: JSON.stringify({ text, model_id: 'eleven_multilingual_v2',
        voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.0, use_speaker_boost: true } }),
    });
    if (!r.ok) throw new Error('TTS ' + r.status + ' ' + (await r.text()).slice(0, 120));
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 1000) throw new Error('audio too small');
    writeFileSync(outPath, buf);
    return 'ok';
  } finally { clearTimeout(to); }
}

const list = JSON.parse(readFileSync(BURN, 'utf8'));
console.log(`要烧 ${list.length} 条 Rosie 音频...`);
let done = 0, skip = 0, fail = 0;
const fails = [];
for (const { base, text } of list) {
  const out = `${ROSIE_DIR}/${base}.mp3`;
  try {
    const r = await tts(text, out);
    if (r === 'skip') { skip++; process.stdout.write('.'); }
    else { done++; process.stdout.write('✓'); }
  } catch (e) {
    fail++; fails.push({ base, err: String(e.message || e) });
    process.stdout.write('✗');
  }
  await sleep(300);
}
console.log(`\n完成:烧 ${done} / 跳过 ${skip} / 失败 ${fail}`);
if (fails.length) { console.log('失败清单:'); fails.forEach(f => console.log(' ', f.base, f.err)); }
