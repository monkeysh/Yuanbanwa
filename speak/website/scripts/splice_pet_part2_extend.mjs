// PET 加强 B2:给现有 PET 话题的 Part 2 独白补可见细节句(内容见 _content-drafts/pet-part2-extend.json)。
// 规则:新句插在 insertBefore 指定的句子之前;句 id 顺延(该档现有最大 n + 1),legacyIds [part2-n];
// 音频 rosie/{sid}_p2_NN.mp3(Part 2 只有 rosie 单声);现有句子的 id / 文本 / 音频零改动;
// 档位 sentenceCount 与顶层 sentenceCount(各档之和)同步。
// 幂等:scenes.json 先做往返校验(parse+stringify 零差异),已合入的句子(按 en 文本)跳过。
// 产出 _content-drafts/pet-part2-extend-burn.json(rosie 清单);烧录用 node scripts/burn_ket_audio.mjs <场景 id...>(已存在的文件跳过)。
// 用法(在 speak/website 下):node scripts/splice_pet_part2_extend.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCENES = path.join(ROOT, 'scenes.json');
const CONTENT = path.join(ROOT, '_content-drafts', 'pet-part2-extend.json');
const BURN = path.join(ROOT, '_content-drafts', 'pet-part2-extend-burn.json');

const pad = n => String(n).padStart(2, '0');
// 展示 token:去首尾非字母数字撇号,词中撇号保留(don't / I'm),纯符号(—)过滤掉。
const tokenize = en => en.split(/\s+/)
  .map(w => w.replace(/^[^A-Za-z0-9']+/, '').replace(/[^A-Za-z0-9']+$/, ''))
  .filter(Boolean);
const wordCount = sents => sents.reduce((n, s) => n + s.en.split(/\s+/).length, 0);

const raw = readFileSync(SCENES, 'utf8');
const data = JSON.parse(raw);
if (JSON.stringify(data, null, 2) + '\n' !== raw) { console.error('❌ scenes.json 不是标准 2 空格格式,拒绝改写'); process.exit(1); }

const seenIds = new Set(data.scenes.flatMap(s => (s.tiers || []).flatMap(t => (t.sentences || []).map(x => x.id))));
const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const burnList = [];
let added = 0, touched = 0;

for (const [sid, spec] of Object.entries(content)) {
  if (sid.startsWith('_')) continue;
  const scene = data.scenes.find(s => s.id === sid);
  if (!scene) { console.error('❌ 场景不存在:', sid); process.exit(1); }
  const tier = (scene.tiers || []).find(t => t.level === 'part2');
  if (!tier) { console.error('❌ 没有 part2 档:', sid); process.exit(1); }
  const at = tier.sentences.findIndex(x => x.id === spec.insertBefore);
  if (at < 0) { console.error(`❌ ${sid}: 找不到 insertBefore 句 ${spec.insertBefore}`); process.exit(1); }

  const existingEn = new Set(tier.sentences.map(x => x.en));
  const fresh = spec.add.filter(s => !existingEn.has(s.en));
  if (!fresh.length) { console.log(`= ${sid}: 已合入,跳过(${tier.sentences.length} 句 / ${wordCount(tier.sentences)} 词)`); continue; }
  if (fresh.length !== spec.add.length) { console.error(`❌ ${sid}: 部分句子已存在,拒绝半合入`); process.exit(1); }

  const prefix = `${sid}-part2-`;
  let maxN = 0;
  for (const x of tier.sentences) {
    if (!x.id.startsWith(prefix)) { console.error(`❌ ${sid}: 句 id 不合规 ${x.id}`); process.exit(1); }
    maxN = Math.max(maxN, Number(x.id.slice(prefix.length)));
  }
  const fresh_sents = fresh.map(s => {
    const n = ++maxN;
    const id = `${prefix}${n}`;
    if (seenIds.has(id)) { console.error('❌ 句 ID 冲突:', id); process.exit(1); }
    seenIds.add(id);
    const base = `${sid}_p2_${pad(n)}`;
    burnList.push({ base, text: s.en });
    return { id, legacyIds: [`part2-${n}`], en: s.en, zh: s.zh, words: tokenize(s.en), weak: [], audio: { rosie: `rosie/${base}.mp3` } };
  });
  tier.sentences.splice(at, 0, ...fresh_sents);
  tier.sentenceCount = tier.sentences.length;
  scene.sentenceCount = scene.tiers.reduce((n, t) => n + t.sentences.length, 0);
  added += fresh_sents.length; touched++;
  console.log(`+ ${sid}: +${fresh_sents.length} 句(${fresh_sents.map(x => x.id.slice(prefix.length)).join(',')})→ ${tier.sentences.length} 句 / ${wordCount(tier.sentences)} 词`);
}

if (!added) { console.log('没有需要合入的句子。'); process.exit(0); }
writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
writeFileSync(BURN, JSON.stringify(burnList, null, 2) + '\n');
const total = data.scenes.reduce((n, s) => n + (s.tiers || []).reduce((m, t) => m + t.sentences.length, 0), 0);
console.log(`✓ 合入 ${touched} 个话题 / ${added} 句;全站 ${data.scenes.length} 场景 / ${total} 句(分档)`);
console.log(`✓ 烧音频清单 ${burnList.length} 条(rosie)→ ${path.relative(ROOT, BURN)}`);
