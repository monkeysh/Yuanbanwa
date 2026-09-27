// 把定稿的 KET 话题(ket-content-new.json)展开成 scenes.json 剑桥场景并追加。
// KET 结构:单 tier(label KET)、8 句一男一女对话;audio map 只放实际用的声线
// (女声句 {rosie}、男声句 {rosie,chris}+voice:chris),不带已删的 bella/alice/george 死链。
// 查重(已存在 id 跳过)、补缺失 examTopics 键、锚点前插入不重排全文件。
// 用法: node splice_ket_new.mjs [content.json]
import { readFileSync, writeFileSync } from 'node:fs';
const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/ket-content-new.json';
const SCENES = '/Users/gelili/Documents/Claude.English/Speak-website/scenes.json';

// 新话题键 → 中文 chip 标签(已存在的键不会重复加)
const TOPIC_LABELS = {
  home: '家居生活', animals: '动物宠物', family: '家庭朋友', health: '健康身体',
  weather: '天气', daily: '日常生活',
};
const kindMap = { family: 'social', daily: 'life', weather: 'life', health: 'life', home: 'life', animals: 'life' };

const tokenize = en => en.split(/\s+/).map(w => w.replace(/^[“”"'(\[]+/, '').replace(/[?.,!;:”“"')\]]+$/, '')).filter(Boolean);
const pad = n => String(n).padStart(2, '0');

const audioFor = (id, n, male) => {
  const base = `${id}_${pad(n)}`;
  const a = { rosie: `rosie/${base}.mp3` };
  if (male) a.chris = `chris/${base}.mp3`; // 男声轮:chris 优先、rosie 回落
  return a;
};
const mkSent = (s, id, i) => {
  const sent = {
    id: `${id}-beginner-${i + 1}`,
    legacyIds: [`beginner-${i + 1}`],
    en: s.en,
    zh: s.zh,
    words: tokenize(s.en),
    weak: [],
    audio: audioFor(id, i + 1, !!s.male),
  };
  if (s.male) sent.voice = 'chris';
  return sent;
};

function buildScene(topic) {
  const id = topic.id;
  const sents = topic.sentences.map((s, i) => mkSent(s, id, i));
  return {
    id, track: 'cambridge', exam: 'KET',
    kind: kindMap[topic.topicKey] || 'social', category: topic.topicKey,
    title: topic.title, subtitle: topic.subtitle, level: 'KET', minutes: 3,
    sentenceCount: sents.length, progress: 0, isNew: true, isFeatured: false,
    description: topic.description,
    learn: topic.learn,
    examPart: topic.examPart, examTip: topic.examTip, templates: topic.templates,
    tiers: [{ level: 'beginner', label: 'KET', sentenceCount: sents.length, sentences: sents }],
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
  console.log('新增 examTopics 键:', newKeys.map(k => `${k}(${TOPIC_LABELS[k] || k})`).join(', '));
}

try { JSON.parse(raw); } catch (e) { console.error('拼接后非法 JSON:', e.message); process.exit(1); }
writeFileSync(SCENES, raw);
const after = JSON.parse(raw);
console.log(`追加 ${fresh.length} 个 KET 场景:`, fresh.map(t => t.id).join(', '));
console.log('scenes 总数:', after.scenes.length, '| examTopics:', after.examTopics.length);
console.log('下一步: node burn_ket_audio.mjs ' + fresh.map(t => t.id).join(' '));
