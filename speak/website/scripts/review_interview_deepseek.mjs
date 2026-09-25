// DeepSeek v4pro(deepseek-reasoner) 双卡审核面试内容:
//   卡① 地道性/中式英语  卡② 难度分档+面试专业性
// 输出每句 verdict(ok/fix) + 问题 + 建议。用法: node review_interview_deepseek.mjs <content.json>
import { readFileSync, writeFileSync } from 'node:fs';

const LEXENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/job-interview.json';

function readKey(p) {
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const t = line.trim();
    if (t.startsWith('DEEPSEEK_QA_API_KEY=')) return t.slice(20).replace(/^"|"$/g, '');
  }
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const t = line.trim();
    if (t.startsWith('DEEPSEEK_API_KEY=')) return t.slice(17).replace(/^"|"$/g, '');
  }
  return null;
}
const KEY = readKey(LEXENV);
if (!KEY) { console.error('未读到 DEEPSEEK key'); process.exit(1); }

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const sents = [];
for (const [level, arr] of Object.entries(content.tiers))
  arr.forEach((s, i) => sents.push({ level, idx: i + 1, en: s.en, zh: s.zh }));

const sys = `你是资深英语面试教练兼母语审校。审核一套「求职面试」跟读句子(全部是求职者对面试官说的话)。两道卡:
卡①地道性:是否母语者自然说法?有无中式英语、生硬直译、语法问题、面试场合不得体?
卡②难度&专业性:难度是否匹配档位(entry=极简短句 / beginner=基础完整句 / intermediate=地道 / advanced=老练复杂)?面试语境是否专业得体?
逐句评估,只把真有问题的标 fix(其余 ok)。fix 时给出改进后的地道英文,尽量保持原意与该档难度。
输出严格 JSON(不要多余文字):
{"reviews":[{"level":"...","idx":N,"en":"原句","verdict":"ok"或"fix","issue":"问题(中文,ok则空)","suggest":"改进英文(fix才有)"}],"overall":"一句话总评(中文)"}`;
const user = sents.map(s => `[${s.level}#${s.idx}] ${s.en}  (原意:${s.zh})`).join('\n');

console.log(`v4pro 双卡审核 ${sents.length} 句...(推理模型较慢,约1-2分钟)`);
const ctrl = new AbortController();
const to = setTimeout(() => ctrl.abort(), 180000);
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
  if (!m) { console.error('未解析到 JSON。原文:', text.slice(0, 500)); process.exit(1); }
  const out = JSON.parse(m[0]);
  writeFileSync(CONTENT.replace(/\.json$/, '-review.json'), JSON.stringify(out, null, 2) + '\n');
  const fixes = (out.reviews || []).filter(x => x.verdict === 'fix');
  console.log(`\n总评: ${out.overall || ''}`);
  console.log(`需修订 ${fixes.length} / ${(out.reviews || []).length} 句:\n`);
  for (const f of fixes) {
    console.log(`  [${f.level}#${f.idx}] ${f.en}`);
    console.log(`    问题: ${f.issue}`);
    console.log(`    建议: ${f.suggest}\n`);
  }
  if (!fixes.length) console.log('  ✓ v4pro 未挑出问题,内容通过双卡');
} finally { clearTimeout(to); }
