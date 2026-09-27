// DeepSeek v4pro(deepseek-reasoner) 双卡审核 FCE 话题内容:
//   卡① 地道性/B2母语自然度(有无中式英语、生硬直译、语法)
//   卡② 难度(是否 B2)+ FCE 考试真实性(Part1深答够不够/Part2独白是否连贯地道符合考风)
// 用法: node review_fce_deepseek.mjs <content.json>
import { readFileSync, writeFileSync } from 'node:fs';

const LEXENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/fce-topics-batch1.json';

function readKey(p) {
  const lines = readFileSync(p, 'utf8').split('\n');
  for (const l of lines) { const t = l.trim(); if (t.startsWith('DEEPSEEK_QA_API_KEY=')) return t.slice(20).replace(/^"|"$/g, ''); }
  for (const l of lines) { const t = l.trim(); if (t.startsWith('DEEPSEEK_API_KEY=')) return t.slice(17).replace(/^"|"$/g, ''); }
  return null;
}
const KEY = readKey(LEXENV);
if (!KEY) { console.error('未读到 DEEPSEEK key'); process.exit(1); }

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const sents = [];
for (const [tid, topic] of Object.entries(content)) {
  if (tid.startsWith('_')) continue;
  for (const part of ['part1', 'part2']) {
    (topic[part] || []).forEach((s, i) => sents.push({ tid, part, idx: i + 1, en: s.en, role: s.voice === 'chris' ? '考生答' : (part === 'part1' ? '考官问' : '考生独白') }));
  }
}

const sys = `你是剑桥 FCE(B2) 口语考官兼母语审校。审核一套 FCE 话题跟读内容,结构:Part1=考官问+考生答(答句应是2-3句、B2深度、有理由/例子);Part2=考生看图独白(应连贯、用衔接词、B2地道)。两道卡:
卡①地道性:是否母语者自然说法?有无中式英语、生硬直译、语法/搭配问题?
卡②难度&考试真实性:是否达到 B2?考官问句是否像真实 FCE?考生答是否够深(不能太短太简单)?Part2 独白是否连贯、衔接自然、符合看图作答的考风?
逐句评估,只把真有问题的标 fix(其余 ok)。fix 给改进后的地道英文,保持原意与 B2 难度。
输出严格 JSON(无多余文字):
{"reviews":[{"tid":"话题id","part":"part1/part2","idx":N,"verdict":"ok/fix","issue":"问题(中文)","suggest":"改进英文(fix才有)"}],"overall":"一句话总评(中文)"}`;
const user = sents.map(s => `[${s.tid}/${s.part}#${s.idx}·${s.role}] ${s.en}`).join('\n');

console.log(`v4pro 双卡审核 ${sents.length} 句 FCE 内容...(推理模型,约2-3分钟)`);
const ctrl = new AbortController();
const to = setTimeout(() => ctrl.abort(), 240000);
try {
  const r = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST', signal: ctrl.signal,
    headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'deepseek-reasoner', messages: [{ role: 'system', content: sys }, { role: 'user', content: user }], max_tokens: 32000, stream: false }),
  });
  if (!r.ok) { console.error('DeepSeek HTTP', r.status, (await r.text()).slice(0, 200)); process.exit(1); }
  const d = await r.json();
  const text = d.choices[0].message.content;
  const m = text.match(/\{[\s\S]*\}/);
  if (!m) { console.error('未解析到 JSON:', text.slice(0, 500)); process.exit(1); }
  const out = JSON.parse(m[0]);
  writeFileSync(CONTENT.replace(/\.json$/, '-review.json'), JSON.stringify(out, null, 2) + '\n');
  const fixes = (out.reviews || []).filter(x => x.verdict === 'fix');
  console.log(`\n总评: ${out.overall || ''}`);
  console.log(`需修订 ${fixes.length} / ${(out.reviews || []).length} 句:\n`);
  for (const f of fixes) {
    console.log(`  [${f.tid}/${f.part}#${f.idx}]`);
    console.log(`    问题: ${f.issue}`);
    console.log(`    建议: ${f.suggest}\n`);
  }
  if (!fixes.length) console.log('  ✓ v4pro 未挑出问题,内容通过双卡');
} finally { clearTimeout(to); }
