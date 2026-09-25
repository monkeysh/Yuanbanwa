// 给指定剑桥场景烧 Rosie 音频 → Speak-website/audio/rosie/<basename>.mp3，
// 并在 scenes.json 给这些句子的 audio map 注入 rosie 键（原始文本替换，不重排全文件）。
// 用法: node gen_rosie.mjs ket-personal pet-travel ...   或   node gen_rosie.mjs --all-cambridge
import { readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from 'node:fs';
import { dirname } from 'node:path';

const VENV = '/Users/gelili/Documents/Claude.English/yuanbanwa-vocab/.env';
const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const SCENES = `${ROOT}/scenes.json`;
const ROSIE_DIR = `${ROOT}/audio/rosie`;

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
if (!key || !voice) { console.error('未读到 key/voice'); process.exit(1); }

const sleep = ms => new Promise(r => setTimeout(r, ms));
const baseOf = sent => {
  const any = sent.audio && (sent.audio.bella || Object.values(sent.audio)[0]);
  if (!any) return null;
  return any.split('/').pop().replace(/\.mp3$/, ''); // e.g. ket-personal_01
};

async function tts(text, outPath) {
  if (existsSync(outPath) && statSync(outPath).size > 1000) return 'skip';
  const ctrl = new AbortController();
  const to = setTimeout(() => ctrl.abort(), 60000); // --max-time 防挂起
  try {
    const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}`, {
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
let ids = process.argv.slice(2);
if (ids[0] === '--all-cambridge') ids = all.scenes.filter(s => s.track === 'cambridge').map(s => s.id);
else if (ids[0] === '--all-daily') ids = all.scenes.filter(s => (s.track || 'daily') === 'daily').map(s => s.id);
if (!ids.length) { console.error('未指定场景 id'); process.exit(1); }

const bases = []; // 待注入 rosie 键的 basename 列表
let n = 0, ok = 0, skip = 0, fail = 0;
for (const id of ids) {
  const sc = all.scenes.find(s => s.id === id);
  if (!sc) { console.error('找不到', id); continue; }
  const tiers = sc.tiers && sc.tiers.length ? sc.tiers : [{ sentences: sc.sentences }];
  const sents = tiers.flatMap(t => t.sentences || []);
  console.log(`\n● ${id} (${sents.length} 句)`);
  for (const s of sents) {
    const base = baseOf(s);
    if (!base) { console.error('  无 audio 路径，跳过一句'); continue; }
    n++;
    const res = await tts(s.en, `${ROSIE_DIR}/${base}.mp3`);
    if (res === 'ok') ok++; else if (res === 'skip') skip++; else { fail++; }
    if (res !== 'fail') bases.push(base);
    process.stdout.write(`  ${res.padEnd(4)} ${base}\n`);
    if (res === 'ok') await sleep(250);
  }
}

// 注入 rosie 键（原始文本替换，basename 唯一）
let raw = readFileSync(SCENES, 'utf8');
let injected = 0;
for (const base of bases) {
  const bellaLine = `"bella": "bella/${base}.mp3"`;
  const rosieLine = `"rosie": "rosie/${base}.mp3"`;
  if (raw.includes(`"rosie/${base}.mp3"`)) continue; // 已注入
  if (!raw.includes(bellaLine)) { console.error('注入锚点未命中:', base); continue; }
  raw = raw.replace(bellaLine, `${rosieLine},\n                ${bellaLine}`);
  injected++;
}
try { JSON.parse(raw); } catch (e) { console.error('注入后非法 JSON:', e.message); process.exit(1); }
writeFileSync(SCENES, raw);
console.log(`\n=== 完成: 句数 ${n} | 新烧 ${ok} | 跳过(已存在) ${skip} | 失败 ${fail} | 注入 rosie 键 ${injected} ===`);
