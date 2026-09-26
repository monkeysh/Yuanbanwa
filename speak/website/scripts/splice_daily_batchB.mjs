// 合入日常批次 B1 / B2:
//   - 给 8 个只有初级档的场景补 entry / intermediate / advanced(现有 beginner 档一字不动);
//   - 新建 car-breakin、insurance-claim 两个场景(插在 emergency-call 之后)。
// 命名沿用批次 A:句 id {sid}-{level}-{n},legacyIds [{level}-{n}],音频 {sid}_{level}_NN.mp3(补零),rosie + chris 双声。
// scenes.json 是标准 2 空格 JSON(parse+stringify 零差异),直接改。幂等:已存在的档 / 场景跳过。
// 同时产出 _content-drafts/daily-batchB-burn.json(rosie 清单,供 burn_daily_audio.mjs);
// 双声烧法:node scripts/burn_ket_audio.mjs <场景 id...>(按 scenes.json 里的路径烧 rosie + chris,已存在的跳过)。
// 用法(在 speak/website 下):node scripts/splice_daily_batchB.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCENES = path.join(ROOT, 'scenes.json');
const BATCHES = ['daily-batchB1.json', 'daily-batchB2.json'].map(f => path.join(ROOT, '_content-drafts', f));
const BURN = path.join(ROOT, '_content-drafts', 'daily-batchB-burn.json');
const INSERT_AFTER = 'emergency-call';

const LABELS = { entry: '入门', beginner: '初级', intermediate: '中级', advanced: '高级' };
const ORDER = ['entry', 'beginner', 'intermediate', 'advanced'];
const pad = n => String(n).padStart(2, '0');
// 展示 token:去首尾非字母数字撇号,词中撇号保留(don't / I'm),纯符号(—)过滤掉。
const tokenize = en => en.split(/\s+/)
  .map(w => w.replace(/^[^A-Za-z0-9']+/, '').replace(/[^A-Za-z0-9']+$/, ''))
  .filter(Boolean);

const raw = readFileSync(SCENES, 'utf8');
const data = JSON.parse(raw);
if (JSON.stringify(data, null, 2) + '\n' !== raw) { console.error('❌ scenes.json 不是标准 2 空格格式,拒绝改写'); process.exit(1); }

const seenIds = new Set(data.scenes.flatMap(s => (s.tiers || []).flatMap(t => (t.sentences || []).map(x => x.id))));
const burnList = [];
let addedTiers = 0, addedSents = 0, addedScenes = 0;

function mkTier(sid, level, sents) {
  const sentences = sents.map((s, i) => {
    const n = i + 1;
    const id = `${sid}-${level}-${n}`;
    if (seenIds.has(id)) { console.error('❌ 句 ID 冲突:', id); process.exit(1); }
    seenIds.add(id);
    const base = `${sid}_${level}_${pad(n)}`;
    burnList.push({ base, text: s.en });
    return { id, legacyIds: [`${level}-${n}`], en: s.en, zh: s.zh, words: tokenize(s.en), weak: [],
      audio: { rosie: `rosie/${base}.mp3`, chris: `chris/${base}.mp3` } };
  });
  return { level, label: LABELS[level], sentenceCount: sentences.length, sentences };
}

function buildScene(sid, batch) {
  const m = batch.meta;
  if (!m) { console.error('❌ 新场景缺 meta:', sid); process.exit(1); }
  const tiers = ORDER.filter(l => Array.isArray(batch[l])).map(l => mkTier(sid, l, batch[l]));
  const beginner = tiers.find(t => t.level === 'beginner');
  return {
    id: sid, kind: m.kind, category: m.category, title: m.title, subtitle: m.subtitle,
    level: m.level, minutes: m.minutes,
    sentenceCount: tiers.reduce((n, t) => n + t.sentences.length, 0),
    progress: 0, isNew: true, isFeatured: false,
    description: m.description,
    learn: m.learn.map(x => x.replace(/\*\*/g, '')),   // 学习要点里的 markdown 加粗不进 UI
    // 顶层 sentences 是初级档的历史镜像(无 id / legacyIds),与其它 daily 场景保持一致
    sentences: beginner ? beginner.sentences.map(({ id, legacyIds, ...rest }) => rest) : [],
    tiers,
  };
}

const newScenes = [];
for (const file of BATCHES) {
  const batch = JSON.parse(readFileSync(file, 'utf8'));
  for (const [sid, content] of Object.entries(batch)) {
    if (sid.startsWith('_')) continue;
    const scene = data.scenes.find(s => s.id === sid);
    if (!scene) {
      if (content._mode !== '新场景') { console.error('❌ 场景不存在且未标记为新场景:', sid); process.exit(1); }
      newScenes.push(buildScene(sid, content));
      addedScenes++;
      continue;
    }
    const byLevel = {};
    for (const t of scene.tiers) byLevel[t.level] = t;
    for (const level of ORDER) {
      if (!Array.isArray(content[level])) continue;
      if (byLevel[level]) { console.log(`跳过已存在 ${sid}/${level}`); continue; }
      byLevel[level] = mkTier(sid, level, content[level]);
      addedTiers++; addedSents += content[level].length;
    }
    scene.tiers = ORDER.filter(l => byLevel[l]).map(l => byLevel[l]);
    scene.sentenceCount = scene.tiers.reduce((n, t) => n + t.sentences.length, 0);
  }
}

if (newScenes.length) {
  const idx = data.scenes.findIndex(s => s.id === INSERT_AFTER);
  if (idx < 0) { console.error('❌ 找不到插入锚点场景:', INSERT_AFTER); process.exit(1); }
  data.scenes.splice(idx + 1, 0, ...newScenes);
  addedSents += newScenes.reduce((n, s) => n + s.sentenceCount, 0);
}

writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
if (burnList.length) writeFileSync(BURN, JSON.stringify(burnList, null, 2) + '\n');   // 幂等重跑时不清空已有清单
const total = data.scenes.reduce((n, s) => n + s.tiers.reduce((m, t) => m + t.sentences.length, 0), 0);
const tiers = data.scenes.reduce((n, s) => n + s.tiers.length, 0);
console.log(`✓ 补档 ${addedTiers} 个 / 新场景 ${addedScenes} 个 / 新增 ${addedSents} 句`);
console.log(`✓ 现在 ${data.scenes.length} 个场景,${tiers} 个 tier,${total} 句`);
console.log(`✓ 烧音频清单 ${burnList.length} 条(rosie)→ ${path.relative(ROOT, BURN)};双声请用 burn_ket_audio.mjs`);
