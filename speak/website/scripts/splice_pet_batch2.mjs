// PET 加强 B1:把 _content-drafts/pet-content-batch2.json 里的新 PET 话题展开成 scenes.json 场景,插在最后一个 PET 场景之后。
// 每话题三档:Part 1 对话(每句 rosie + chris 双声,考生答句 voice=chris)、Part 2 独白(rosie 单声)、Part 3 讨论(A 轮 rosie,B 轮 rosie + chris 并 voice=chris)。
// 句 id {sid}-{part}-{n},legacyIds [{part}-{n}],音频 {sid}_p1|p2|p3_NN.mp3;顶层 sentenceCount = 各档之和;examTopics 键必须已存在(不新增芯片)。
// 幂等:scenes.json 先做往返校验;已存在的场景 id 跳过。产出 _content-drafts/pet-topics-batch2-burn.json({base,text,voices})。
// 用法(在 speak/website 下):node scripts/splice_pet_batch2.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCENES = path.join(ROOT, 'scenes.json');
const CONTENT = path.join(ROOT, '_content-drafts', 'pet-content-batch2.json');
const BURN = path.join(ROOT, '_content-drafts', 'pet-topics-batch2-burn.json');
const EXAM = 'PET';
const LABELS = { part1: 'Part 1 对话', part2: 'Part 2 独白', part3: 'Part 3 讨论' };
const AUDIO_TIER = { part1: 'p1', part2: 'p2', part3: 'p3' };

const pad = n => String(n).padStart(2, '0');
// 展示 token:去首尾非字母数字撇号,词中撇号保留(don't / I'm),纯符号(—)过滤掉。
const tokenize = en => en.split(/\s+/)
  .map(w => w.replace(/^[^A-Za-z0-9']+/, '').replace(/[^A-Za-z0-9']+$/, ''))
  .filter(Boolean);
const fail = m => { console.error('❌', m); process.exit(1); };

const raw = readFileSync(SCENES, 'utf8');
const data = JSON.parse(raw);
if (JSON.stringify(data, null, 2) + '\n' !== raw) fail('scenes.json 不是标准 2 空格格式,拒绝改写');
const topicKeys = new Set(data.examTopics.map(t => t.key));
const seenIds = new Set(data.scenes.flatMap(s => (s.tiers || []).flatMap(t => (t.sentences || []).map(x => x.id))));
const burnList = [];

function check(t) {
  if (!/^pet-[a-z]+$/.test(t.id)) fail(`${t.id}: id 不合规`);
  if (!topicKeys.has(t.topicKey)) fail(`${t.id}: examTopics 里没有键 ${t.topicKey}`);
  if (!['life', 'social', 'travel', 'school', 'urgent'].includes(t.kind)) fail(`${t.id}: kind 不合规 ${t.kind}`);
  if ((t.templates || []).length !== 4) fail(`${t.id}: templates ≠ 4`);
  if ((t.part1 || []).length !== 8) fail(`${t.id}: part1 ≠ 8`);
  t.part1.forEach((s, i) => { if ((i % 2 === 1) !== (s.voice === 'chris')) fail(`${t.id}: part1 第 ${i + 1} 句 voice 不是考官/考生交替`); });
  const p2 = t.part2?.sentences || [];
  if (p2.length < 8 || p2.length > 10) fail(`${t.id}: part2 ${p2.length} 句,应为 8–10`);
  const words = p2.reduce((n, s) => n + s.en.split(/\s+/).length, 0);
  if (words < 110 || words > 135) fail(`${t.id}: part2 ${words} 词,应为 110–135`);
  const p3 = t.part3?.sentences || [];
  if (p3.length !== 12) fail(`${t.id}: part3 ≠ 12`);
  p3.forEach((s, i) => { if (s.voice !== (i % 2 ? 'chris' : 'rosie')) fail(`${t.id}: part3 第 ${i + 1} 句 voice 应为 ${i % 2 ? 'chris' : 'rosie'}`); });
  if ((t.examTip || '').length < 80) fail(`${t.id}: examTip 太短`);
  if (!t.part2.prompt || !t.part3.task) fail(`${t.id}: 缺 part2.prompt / part3.task`);
  for (const s of [...t.part1, ...p2, ...p3]) if (!s.en || !s.zh) fail(`${t.id}: 有句子缺 en/zh`);
}

function mkSentence(sid, part, i, s, voices) {
  const n = i + 1;
  const id = `${sid}-${part}-${n}`;
  if (seenIds.has(id)) fail(`句 ID 冲突: ${id}`);
  seenIds.add(id);
  const base = `${sid}_${AUDIO_TIER[part]}_${pad(n)}`;
  const audio = Object.fromEntries(voices.map(v => [v, `${v}/${base}.mp3`]));
  burnList.push({ base, text: s.en, voices });
  const out = { id, legacyIds: [`${part}-${n}`], en: s.en, zh: s.zh, words: tokenize(s.en), weak: [], audio };
  if (s.voice === 'chris') out.voice = 'chris';
  return out;
}

function buildScene(t) {
  const sid = t.id;
  const p1 = t.part1.map((s, i) => mkSentence(sid, 'part1', i, s, ['rosie', 'chris']));
  const p2 = t.part2.sentences.map((s, i) => mkSentence(sid, 'part2', i, s, ['rosie']));
  const p3 = t.part3.sentences.map((s, i) => mkSentence(sid, 'part3', i, s, s.voice === 'chris' ? ['rosie', 'chris'] : ['rosie']));
  const tiers = [['part1', p1], ['part2', p2], ['part3', p3]].map(([level, sentences]) => ({ level, label: LABELS[level], sentenceCount: sentences.length, sentences }));
  return {
    id: sid, track: 'cambridge', exam: EXAM, kind: t.kind, category: t.topicKey,
    title: t.title, subtitle: t.subtitle, level: EXAM, minutes: 4,
    sentenceCount: tiers.reduce((n, x) => n + x.sentences.length, 0),
    progress: 0, isNew: true, isFeatured: false,
    description: `${EXAM} 口语 · ${t.title} · Part 1 面试问答 + Part 2 看图描述长描述 + Part 3 讨论`,
    learn: t.templates.slice(0, 3).map(x => x.zh),
    examPart: t.examPart, examTip: t.examTip, templates: t.templates,
    tiers,
  };
}

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const existing = new Set(data.scenes.map(s => s.id));
const fresh = content.topics.filter(t => !existing.has(t.id));
const skipped = content.topics.filter(t => existing.has(t.id)).map(t => t.id);
if (skipped.length) console.log('= 已存在,跳过:', skipped.join(', '));
if (!fresh.length) { console.log('没有新话题可加。'); process.exit(0); }
fresh.forEach(check);

let insertAt = -1;
data.scenes.forEach((s, i) => { if (s.id.startsWith('pet-')) insertAt = i; });
if (insertAt < 0) fail('找不到 PET 场景锚点');
const scenes = fresh.map(buildScene);
data.scenes.splice(insertAt + 1, 0, ...scenes);

writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
writeFileSync(BURN, JSON.stringify(burnList, null, 2) + '\n');
const total = data.scenes.reduce((n, s) => n + (s.tiers || []).reduce((m, t) => m + t.sentences.length, 0), 0);
const files = burnList.reduce((n, b) => n + b.voices.length, 0);
console.log(`✓ 新增 ${scenes.length} 个 ${EXAM} 场景(插在 ${data.scenes[insertAt].id} 之后):`, scenes.map(s => `${s.id}(${s.sentenceCount} 句)`).join(', '));
console.log(`✓ 全站 ${data.scenes.length} 场景 / ${total} 句(分档);烧音频清单 ${burnList.length} 句 / ${files} 个文件 → ${path.relative(ROOT, BURN)}`);
