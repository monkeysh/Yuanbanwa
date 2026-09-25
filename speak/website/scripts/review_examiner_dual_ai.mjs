// 双 AI 独立审核「模拟考官问题体检表」:DeepSeek v4pro + Qwen3.7-plus 各审一遍,再对比汇总。
// 目的:用户英语能力有限,靠多 AI 交叉覆盖大范围质检。
// 用法: node review_examiner_dual_ai.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const TABLE = `${ROOT}/_content-drafts/考官问题体检表.md`;

function readEnvVal(p, key) {
  try {
    for (const line of readFileSync(p, 'utf8').split('\n')) {
      const t = line.trim();
      if (t.startsWith(key + '=')) return t.slice(key.length + 1).replace(/^"|"$/g, '');
    }
  } catch {}
  return null;
}
const DS_KEY = readEnvVal('/Users/gelili/Documents/Claude.English/Lexile/.env', 'DEEPSEEK_QA_API_KEY')
            || readEnvVal('/Users/gelili/Documents/Claude.English/Lexile/.env', 'DEEPSEEK_API_KEY');
const QWEN_KEY = readEnvVal('/Users/gelili/Documents/Claude.English/server/.env', 'QWEN_API_KEY');
if (!DS_KEY) { console.error('缺 DeepSeek key'); process.exit(1); }
if (!QWEN_KEY) { console.error('缺 Qwen key'); process.exit(1); }

// 解析体检表 → [{scene, exam, dim, zh, en}]
const md = readFileSync(TABLE, 'utf8');
const items = [];
for (const sec of md.split('## ').slice(1)) {
  const head = sec.split('\n')[0].trim();               // "买一件 T 恤 · KET"
  const [scene, exam] = head.split(' · ');
  for (const m of sec.matchAll(/^\| ([^|]+) \| \*\*([^*]*)\*\* \| ([^|]*) \|$/gm)) {
    items.push({ scene: scene.trim(), exam: (exam || 'KET').trim(), dim: m[1].trim(), zh: m[2].trim(), en: m[3].trim() });
  }
}
console.log(`解析到 ${items.length} 个考官问题,交给 v4pro + Qwen 独立审核...\n`);

const SYS = `你是剑桥英语(KET=A2 / PET=B1 / FCE=B2)口语考官。下面是一个「AI 模拟考官」在各个场景、各个提问维度下真实生成的问题清单。
背景:这是给中国学生的口语备考 App,AI 考官按「场景话题 × 提问维度」出题,学生要开口作答。

请挑出**有问题的**问题,四类:
A. **问得怪/不自然**:真实考官不会这么问,或中文母语者一看就别扭。
B. **学生答不上**:对该级别(KET=A2/PET=B1/FCE=B2)的学生,这问题没法答或没东西可说(例如问一个日常动作"有什么困难")。
C. **维度不符**:问题和它标注的维度对不上(例如标"给人建议"却在问个人习惯)。
D. **不像真实考试**:不符合剑桥该级别 Part 1 的问法。

只列真有问题的(没问题的别列)。每条给:场景、维度、问题类型(A/B/C/D)、原因(中文)、你建议改成什么(英文 + 中文)。
输出严格 JSON(无多余文字):
{"issues":[{"scene":"场景名","dim":"维度","type":"A/B/C/D","reason":"原因(中文)","suggest_en":"建议英文问法","suggest_zh":"中文"}],"overall":"一句话总评(中文):这批考官问题整体质量如何、主要毛病是什么"}`;

const USER = items.map((it, i) => `${i + 1}. [${it.exam}·${it.scene}·维度=${it.dim}] ${it.en}  (中文:${it.zh})`).join('\n');

async function callDeepSeek() {
  const r = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${DS_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'deepseek-reasoner', messages: [{ role: 'system', content: SYS }, { role: 'user', content: USER }], max_tokens: 32000, stream: false }),
  });
  if (!r.ok) throw new Error('DeepSeek HTTP ' + r.status + ' ' + (await r.text()).slice(0, 150));
  const d = await r.json();
  return d.choices[0].message.content;
}
async function callQwen() {
  const r = await fetch('https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${QWEN_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'qwen3.7-plus', messages: [{ role: 'system', content: SYS }, { role: 'user', content: USER }], max_tokens: 8000, enable_thinking: false, stream: false }),
  });
  if (!r.ok) throw new Error('Qwen HTTP ' + r.status + ' ' + (await r.text()).slice(0, 150));
  const d = await r.json();
  return d.choices[0].message.content;
}
const parse = (txt, who) => {
  const m = txt.match(/\{[\s\S]*\}/);
  if (!m) { console.error(`${who} 未返回 JSON:`, txt.slice(0, 200)); return { issues: [], overall: '(解析失败)' }; }
  try { return JSON.parse(m[0]); } catch (e) { console.error(`${who} JSON 解析失败:`, e.message); return { issues: [], overall: '(解析失败)' }; }
};

const [dsTxt, qwTxt] = await Promise.all([
  callDeepSeek().catch(e => { console.error('DeepSeek 失败:', e.message); return '{}'; }),
  callQwen().catch(e => { console.error('Qwen 失败:', e.message); return '{}'; }),
]);
const ds = parse(dsTxt, 'DeepSeek'), qw = parse(qwTxt, 'Qwen');

const key = i => `${i.scene}|${i.dim}`;
const dsMap = new Map((ds.issues || []).map(i => [key(i), i]));
const qwMap = new Map((qw.issues || []).map(i => [key(i), i]));
const both = [...dsMap.keys()].filter(k => qwMap.has(k));

console.log(`\n═══ v4pro:挑出 ${(ds.issues || []).length} 处 ═══`);
console.log('总评:', ds.overall);
console.log(`\n═══ Qwen3.7:挑出 ${(qw.issues || []).length} 处 ═══`);
console.log('总评:', qw.overall);
console.log(`\n═══ 两个 AI 都认为有问题(${both.length} 处 · 优先修)═══`);
for (const k of both) {
  const a = dsMap.get(k), b = qwMap.get(k);
  console.log(`\n【${k}】type=${a.type}`);
  console.log(`  v4pro: ${a.reason}`);
  console.log(`         → ${a.suggest_en}`);
  console.log(`  Qwen : ${b.reason}`);
  console.log(`         → ${b.suggest_en}`);
}
writeFileSync(`${ROOT}/_content-drafts/考官问题-双AI审核.json`,
  JSON.stringify({ deepseek: ds, qwen: qw, agreedKeys: both }, null, 2) + '\n');
console.log(`\n结果已存 _content-drafts/考官问题-双AI审核.json`);
