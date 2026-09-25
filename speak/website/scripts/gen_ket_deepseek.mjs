// 用 DeepSeek v4pro 生成 KET(A2)新话题「跟读对话」内容 → _content-drafts/ket-content-new.json
// 不吃 Claude 额度;跑的是 DeepSeek API(key/模型从 Lexile/.env 读)。
// KET 结构 ≠ PET:KET 是纯 8 句一男一女对话(非 Part1/Part2),配 learn/examPart/examTip(三段)/templates。
// 用法: node gen_ket_deepseek.mjs            (生成下面 TOPICS 全部)
//       node gen_ket_deepseek.mjs ket-family (只生成指定 id)
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
const ENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const OUT = '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/ket-content-new.json';

// ★ 想扩更多话题就改这个列表(id 用 ket-<topicKey>,topicKey 决定话题 chip 归类)
const TOPICS = [
  { id: 'ket-family',  topicKey: 'family',  theme: '家庭与朋友(家里有谁、和谁最亲、朋友叫什么、周末和家人朋友做什么)' },
  { id: 'ket-daily',   topicKey: 'daily',   theme: '日常作息(几点起床/上学/睡觉、每天做什么、周末和平时的不同)' },
  { id: 'ket-weather', topicKey: 'weather', theme: '天气与季节(今天天气怎样、喜欢的季节、不同天气穿什么/做什么)' },
  { id: 'ket-health',  topicKey: 'health',  theme: '健康与身体(觉得怎么样、哪里不舒服、怎样保持健康、看医生)' },
  { id: 'ket-home',    topicKey: 'home',    theme: '我的家(住在哪、家里有几个房间、最喜欢的房间、房间里有什么)' },
  { id: 'ket-animals', topicKey: 'animals', theme: '动物与宠物(有没有宠物、喜欢什么动物、宠物叫什么/长什么样/爱做什么)' },
];

const env = p => { const o = {}; for (const l of readFileSync(p, 'utf8').split('\n')) { const m = l.match(/^([A-Z_]+)=(.*)$/); if (m) o[m[1]] = m[2].replace(/^"|"$/g, ''); } return o; };
const E = env(ENV);
const KEY = E.DEEPSEEK_GEN_API_KEY || E.DEEPSEEK_QA_API_KEY || E.DEEPSEEK_API_KEY;

const SYS = `你是剑桥英语 KET(A2 Key)口语教研专家,为「跟读(shadowing)」备考 App 生成内容,供中国小学到初中低龄学生跟读练习。必须 CEFR A2 级准确、口语自然、句子短而地道、词汇简单(A2 范围)。严格输出 JSON,不要解释、不要 markdown。`;

const schema = `按此 JSON schema 输出单个对象:
{
  "id": "<给定 id>",
  "topicKey": "<给定 topicKey>",
  "title": "中文标题(4-8字,生动亲切,如「聊聊我的家人」)",
  "subtitle": "English subtitle (2-4 words, e.g. My family)",
  "description": "中文一句话说明(20-35字,说这段对话练什么、KET 里这个话题常聊什么)",
  "learn": ["3 个中文学习点,每个 6-12 字,如 介绍家庭成员 / 说和谁最亲 / 问朋友的情况"],
  "examPart": "话题拓展｜<4-6字场景名,如 认识我的家人>",
  "examTip": "中文考点说明,三段,每段以加粗小标题开头,用 \\n 分段,共 ≥100 字:\\n**考法** 说明这个话题在 KET 里怎么出现;并明确写出『这段是生活对话拓展,不是真实 Speaking Part 1 考场流程。真实 Part 1 是考官问、考生答』。\\n**掌握** 列出该练的核心 A2 句型/词(用 / 分隔,如 There is/are… / I live with… / My favourite… is…)。\\n**注意** 一条实用提醒(如 回答用完整短句,别只蹦单词)。",
  "templates": [
    {"en": "A2 万能句型带 ___ 空,如 There are ___ people in my family.", "zh": "中文用途,如 说家里几口人"}
  ],
  "sentences": [
    {"en": "对话的一句(A2,短、地道、口语)", "zh": "中文翻译", "male": true}
  ]
}
硬性要求:
- templates 正好 4 个(A2 级万能句型,带 ___ 空,贴合话题)。
- sentences 正好 8 句,是【两个人一问一答的自然对话】(一男一女,如男孩 Tom / 女孩 Lily),交替进行、上下句衔接连贯、围绕主题层层展开;A2 词汇语法(一般现在时、can、there is/are、like/love doing、have got、简单 because);每句短(6-14 词),口语地道,不要书面语。
- 每句用 "male": true 表示男声说的,"male": false 表示女声说的,严格男女交替(第1句可男可女)。
- 一律不许留空。中文翻译准确自然、口语化。`;

async function gen(topic) {
  const user = `为话题生成 KET(A2)口语跟读【对话】内容。id=${topic.id},topicKey=${topic.topicKey},主题:${topic.theme}。\n\n${schema}`;
  const body = JSON.stringify({
    model: 'deepseek-v4-pro',
    messages: [{ role: 'system', content: SYS }, { role: 'user', content: user }],
    temperature: 0.3, max_tokens: 32000, response_format: { type: 'json_object' }, stream: false,
  });
  const ctrl = new AbortController(); const to = setTimeout(() => ctrl.abort(), 300000);
  try {
    const r = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST', signal: ctrl.signal,
      headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/json' }, body,
    });
    if (!r.ok) return { error: `HTTP ${r.status}: ${(await r.text()).slice(0, 200)}` };
    const d = await r.json();
    let raw = d.choices[0].message.content.trim();
    if (raw.startsWith('```')) raw = raw.replace(/^```(?:json)?\s*/, '').replace(/\s*```$/, '');
    raw = raw.replace(/,(\s*[}\]])/g, '$1');
    return { obj: JSON.parse(raw), usage: d.usage };
  } catch (e) { return { error: e.message }; } finally { clearTimeout(to); }
}

function validate(o, topic) {
  const errs = [];
  if (o.id !== topic.id) errs.push('id 不符');
  if (o.topicKey !== topic.topicKey) errs.push('topicKey 不符');
  if ((o.templates || []).length !== 4) errs.push(`templates=${(o.templates || []).length}≠4`);
  if ((o.sentences || []).length !== 8) errs.push(`sentences=${(o.sentences || []).length}≠8`);
  if ((o.learn || []).length !== 3) errs.push(`learn=${(o.learn || []).length}≠3`);
  if ((o.examTip || '').length < 80) errs.push(`examTip 太短(${(o.examTip || '').length})`);
  for (const f of ['title', 'subtitle', 'description', 'examPart']) if (!o[f]) errs.push(`缺 ${f}`);
  // 男女是否有交替(至少各出现一次)
  const males = (o.sentences || []).filter(s => s.male === true).length;
  if (males === 0 || males === (o.sentences || []).length) errs.push('对话未男女交替');
  return errs;
}

let ids = process.argv.slice(2);
const todo = ids.length ? TOPICS.filter(t => ids.includes(t.id)) : TOPICS;
const out = existsSync(OUT) ? JSON.parse(readFileSync(OUT, 'utf8')) : [];
const byId = new Map(out.map(o => [o.id, o]));

for (const topic of todo) {
  const t0 = Date.now();
  const res = await gen(topic);
  const secs = ((Date.now() - t0) / 1000).toFixed(0);
  if (res.error) { console.log(`✗ ${topic.id} (${secs}s) ERROR ${res.error}`); continue; }
  const errs = validate(res.obj, topic);
  if (errs.length) console.log(`⚠ ${topic.id} (${secs}s) 校验未过: ${errs.join('; ')} —— 已存,请人工看`);
  else console.log(`✓ ${topic.id} (${secs}s) OK tok=${res.usage?.total_tokens || '?'}`);
  byId.set(topic.id, res.obj);
}
const arr = TOPICS.map(t => byId.get(t.id)).filter(Boolean);
writeFileSync(OUT, JSON.stringify(arr, null, 2));
console.log(`\n写入 ${arr.length} 个话题 → ${OUT}`);
