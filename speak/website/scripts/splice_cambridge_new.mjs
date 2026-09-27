// 把新生成的剑桥话题(pet-content-new.json 等)展开成 scenes.json 场景并追加。
// 查重(已存在的 id 跳过)、自动补缺失的 examTopics 键、不重排全文件(锚点前插入)。
// 用法: node splice_cambridge_new.mjs <content.json> <PET|FCE>
import { readFileSync, writeFileSync } from 'node:fs';
const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/pet-content-new.json';
const EXAM = process.argv[3] || 'PET';
const SCENES = '/Users/gelili/Documents/Claude.English/Speak-website/scenes.json';
const VOICES = ['bella', 'alice', 'chris', 'george'];

// 新话题键 → 中文 chip 标签(已存在的键不会重复加)
const TOPIC_LABELS = {
  health: '健康身体', weather: '天气', entertainment: '娱乐媒体', technology: '科技网络',
  work: '工作职业', family: '家庭朋友', sports: '运动', music: '音乐', festival: '节日',
  nature: '自然动物', clothes: '服装', internet: '网络',
};

const tokenize = en => en.split(/\s+/).map(w => w.replace(/^[“”"'(\[]+/, '').replace(/[?.,!;:”“"')\]]+$/, '')).filter(Boolean);
const pad = n => String(n).padStart(2, '0');
const audioFor = (id, tier, n) => Object.fromEntries(VOICES.map(v => [v, `${v}/${id}_${tier}_${pad(n)}.mp3`]));
const mkSent = (s, id, audioTier, i) => {
  const tier = audioTier === 'p1' ? 'part1' : audioTier === 'p2' ? 'part2' : audioTier;
  return {
    id: `${id}-${tier}-${i + 1}`,
    legacyIds: [`${tier}-${i + 1}`],
    en: s.en,
    zh: s.zh,
    words: tokenize(s.en),
    weak: [],
    audio: audioFor(id, audioTier, i + 1),
  };
};
const kindMap = { health: 'life', weather: 'life', entertainment: 'social', technology: 'social', work: 'school', family: 'social', sports: 'life', music: 'social' };

function buildScene(topic) {
  const id = topic.id;
  const p1 = topic.part1.map((s, i) => mkSent(s, id, 'p1', i));
  const p2 = topic.part2.sentences.map((s, i) => mkSent(s, id, 'p2', i));
  const part2Kind = EXAM === 'FCE' ? '对比两图' : '看图描述';
  return {
    id, track: 'cambridge', exam: EXAM,
    kind: kindMap[topic.topicKey] || 'social', category: topic.topicKey,
    title: topic.title, subtitle: topic.subtitle, level: EXAM, minutes: 4,
    sentenceCount: p1.length, progress: 0, isNew: true, isFeatured: false,
    description: `${EXAM} 口语 · ${topic.title} · Part 1 面试问答 + Part 2 ${part2Kind}长描述`,
    learn: topic.templates.slice(0, 3).map(t => t.zh),
    examPart: topic.examPart, examTip: topic.examTip, templates: topic.templates,
    tiers: [
      { level: 'part1', label: 'Part 1 对话', sentenceCount: p1.length, sentences: p1 },
      { level: 'part2', label: EXAM === 'FCE' ? 'Part 2 独白' : 'Part 2 独白', sentenceCount: p2.length, sentences: p2 },
    ],
  };
}

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
let raw = readFileSync(SCENES, 'utf8');
const existingIds = new Set(JSON.parse(raw).scenes.map(s => s.id));
const existingTopics = new Set(JSON.parse(raw).examTopics.map(t => t.key));

const fresh = content.filter(t => !existingIds.has(t.id));
const dup = content.filter(t => existingIds.has(t.id)).map(t => t.id);
if (dup.length) console.log('跳过已存在:', dup.join(', '));
if (!fresh.length) { console.log('没有新话题可加。'); process.exit(0); }

const indent4 = obj => JSON.stringify(obj, null, 2).split('\n').map(l => '    ' + l).join('\n');
const scenesText = fresh.map(t => indent4(buildScene(t))).join(',\n');

const anchor = '    }\n  ],\n  "examTopics": [';
if (!raw.includes(anchor)) { console.error('找不到 scenes/examTopics 锚点'); process.exit(1); }
raw = raw.replace(anchor, `    },\n${scenesText}\n  ],\n  "examTopics": [`);

// 补缺失的 examTopics 键
const newKeys = [...new Set(fresh.map(t => t.topicKey))].filter(k => !existingTopics.has(k));
if (newKeys.length) {
  const topicsText = newKeys.map(k => `    {\n      "key": "${k}",\n      "label": "${TOPIC_LABELS[k] || k}"\n    }`).join(',\n');
  raw = raw.replace('  "examTopics": [\n', `  "examTopics": [\n${topicsText},\n`);
  console.log('新增 examTopics 键:', newKeys.join(', '));
}

try { JSON.parse(raw); } catch (e) { console.error('拼接后非法 JSON:', e.message); process.exit(1); }
writeFileSync(SCENES, raw);
const after = JSON.parse(raw);
console.log(`追加 ${fresh.length} 个 ${EXAM} 场景:`, fresh.map(t => t.id).join(', '));
console.log('scenes 总数:', after.scenes.length, '| examTopics:', after.examTopics.length);
console.log('下一步:① node gen_rosie.mjs ' + fresh.map(t => t.id).join(' ') + '   ② node ensure_rosie_keys.mjs');
