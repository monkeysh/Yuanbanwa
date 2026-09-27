// 用 DeepSeek v4pro 生成 PET(B1)新话题内容 → scratchpad/pet-content-new.json
// 不吃 Claude 额度;跑的是 DeepSeek API(key/模型从 Lexile/.env 读)。
// 用法: node gen_pet_deepseek.mjs            (生成下面 TOPICS 全部)
//       node gen_pet_deepseek.mjs pet-health (只生成指定 id)
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
const ENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const OUT = '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/pet-content-new.json';

// ★ 想扩更多话题就改这个列表(id 用 pet-<topicKey>,topicKey 决定话题 chip 归类)
const TOPICS = [
  { id: 'pet-health',        topicKey: 'health',        theme: '健康与运动(保持健康、做什么运动、饮食习惯)' },
  { id: 'pet-weather',       topicKey: 'weather',       theme: '天气与季节(喜欢的季节、不同天气做什么、家乡气候)' },
  { id: 'pet-entertainment', topicKey: 'entertainment', theme: '电影与音乐(喜欢的电影/音乐、影院还是在家看、乐器)' },
  { id: 'pet-technology',    topicKey: 'technology',    theme: '手机与上网(日常怎么用手机、常用 app、网络的好处与问题)' },
  { id: 'pet-work',          topicKey: 'work',          theme: '未来工作(理想职业、为什么、做过的兼职或家务)' },
  { id: 'pet-family',        topicKey: 'family',        theme: '家庭与朋友(家里有谁、和谁最亲、和朋友周末做什么)' },
];

const env = p => { const o = {}; for (const l of readFileSync(p, 'utf8').split('\n')) { const m = l.match(/^([A-Z_]+)=(.*)$/); if (m) o[m[1]] = m[2].replace(/^"|"$/g, ''); } return o; };
const E = env(ENV);
const KEY = E.DEEPSEEK_GEN_API_KEY || E.DEEPSEEK_QA_API_KEY || E.DEEPSEEK_API_KEY;

const SYS = `你是剑桥英语 PET(B1 Preliminary)口语教研专家,为「跟读(shadowing)」备考 App 生成内容,供中国学生跟读练习。必须 CEFR B1 级准确、口语自然、考试真实。严格输出 JSON,不要解释、不要 markdown。`;

const schema = `按此 JSON schema 输出单个对象:
{
  "id": "<给定 id>",
  "topicKey": "<给定 topicKey>",
  "title": "中文标题(4-8字,生动,如「聊聊健康习惯」)",
  "subtitle": "English subtitle (3-5 words, e.g. Staying healthy)",
  "examPart": "Part 1 + Part 2",
  "examTip": "中文考点说明,≥80字。说明这个话题在 PET 口语 Part 1(考官面试问答)和 Part 2(描述一张彩色照片做约1分钟个人长说)里会怎么考、考官常问什么、B1 学生要注意什么(完整句、连接词、给理由/例子)。措辞用『通常会自然用到』而非『要求用』。有真实教学价值,别空泛。",
  "templates": [
    {"en": "万能句型带 ___ 空,B1 级,如 I usually ___ to keep fit.", "zh": "中文用途,如 说健康习惯"}
  ],
  "part1": [
    {"en": "Examiner/Candidate 的一句", "zh": "中文翻译"}
  ],
  "part2": {
    "prompt": "中文任务说明,如「描述一张关于运动的照片:说说照片里有谁、在哪里、在做什么、可能的心情。」",
    "sentences": [{"en": "model long-turn 的一句", "zh": "中文翻译"}]
  }
}
硬性要求:templates 正好 4 个;part1 正好 8 句(考官问与考生答交替,B1 词汇语法:一般现在/过去/将来、be going to、present perfect、比较级、because/so/but/also,考生答1-2句完整给理由);part2.sentences 正好 6 句(连贯单图描述独白,用 In the picture…/There is/are…/present continuous/It looks like…/maybe/probably/I think…)。一律不许留空。中文翻译准确自然。`;

async function gen(topic) {
  const user = `为话题生成 PET(B1)口语跟读内容。id=${topic.id},topicKey=${topic.topicKey},主题:${topic.theme}。\n\n${schema}`;
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
  if ((o.part1 || []).length !== 8) errs.push(`part1=${(o.part1 || []).length}≠8`);
  if ((o.part2?.sentences || []).length !== 6) errs.push(`part2=${(o.part2?.sentences || []).length}≠6`);
  if ((o.examTip || '').length < 60) errs.push(`examTip 太短(${(o.examTip || '').length})`);
  for (const f of ['title', 'subtitle', 'examPart']) if (!o[f]) errs.push(`缺 ${f}`);
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
  if (errs.length) { console.log(`⚠ ${topic.id} (${secs}s) 校验未过: ${errs.join('; ')} —— 已存,请人工看`); }
  else console.log(`✓ ${topic.id} (${secs}s) OK tok=${res.usage?.total_tokens || '?'}`);
  byId.set(topic.id, res.obj);
}
const arr = TOPICS.map(t => byId.get(t.id)).filter(Boolean);
writeFileSync(OUT, JSON.stringify(arr, null, 2));
console.log(`\n写入 ${arr.length} 个话题 → ${OUT}`);
