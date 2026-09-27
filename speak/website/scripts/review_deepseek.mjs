// Phase A: DeepSeek v4-pro 逐话题二次审核剑桥口语内容 → scratchpad/review/<id>.deepseek.json
// 用法: node review_deepseek.mjs pet-travel          (单话题试跑)
//       node review_deepseek.mjs --all-cambridge      (全部 18)
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
const ENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const SCENES = '/Users/gelili/Documents/Claude.English/Speak-website/scenes.json';
const OUT = '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/review';
mkdirSync(OUT, { recursive: true });

function env(p) { const o = {}; for (const l of readFileSync(p, 'utf8').split('\n')) { const m = l.match(/^([A-Z_]+)=(.*)$/); if (m) o[m[1]] = m[2].replace(/^"|"$/g, ''); } return o; }
const E = env(ENV);
const KEY = E.DEEPSEEK_GEN_API_KEY || E.DEEPSEEK_QA_API_KEY || E.DEEPSEEK_API_KEY;
const MODEL = 'deepseek-v4-pro';

const LEVEL = { KET: 'A2', PET: 'B1', FCE: 'B2' };

function contentOf(sc) {
  const tiers = sc.tiers || [];
  const p1tier = tiers.find(t => t.level === 'part1') || tiers.find(t => t.level === 'beginner') || tiers[0];
  const p2tier = tiers.find(t => t.level === 'part2');
  const strip = s => ({ en: s.en, zh: s.zh });
  return {
    id: sc.id, exam: sc.exam, cefr: LEVEL[sc.exam] || '?', title: sc.title, subtitle: sc.subtitle,
    examPart: sc.examPart || '', examTip: sc.examTip || '',
    templates: sc.templates || [],
    part1: (p1tier?.sentences || []).map(strip),
    part2: p2tier ? { prompt: '', sentences: p2tier.sentences.map(strip) } : null,
  };
}

const SYS = `你是剑桥英语口语考试(KET/PET/FCE)资深考官 + 教材主编。审核一段给中国学生的「跟读备考」内容(用于付费产品),严格逐条挑错,宁严勿松。
审核维度:
① CEFR 级别名实相符(KET=A2 / PET=B1 / FCE=B2):过难或过易、词汇/句法不符该级别,都要指出。
② 英文地道自然:语法、搭配、用词、冠词、时态、口语 vs 书面语,任何不自然或错误都报。
③ 符合该考试该 Part 的真实考法(KET Part1 面试问答;PET/FCE Part1 面试 + Part2 个人长描述/对比两图)。
④ examTip(考点说明)准确、有真实教学价值、无误导或硬套。
⑤ templates(答题模板)可迁移、级别合适、句型正确。
⑥ 中文翻译准确、自然、与英文一致(漏译/错译/不一致都报)。
⑦ 一致性:同话题内重复、矛盾、与 examPart 标注不符。
只报真问题(没问题就空数组),每条给出可直接采用的修正。严格输出 JSON,不要解释、不要 markdown。`;

const schema = `输出 JSON：
{
  "id": "<原 id>",
  "verdict": "pass | minor | major",
  "issues": [
    { "field": "examTip | templates[i] | part1[i].en | part1[i].zh | part2.sentences[i].en | part2.sentences[i].zh | overall",
      "severity": "low | med | high",
      "problem": "具体问题(指出原文哪里)",
      "fix": "建议修正(直接可用的替换文本)" }
  ],
  "overallComment": "一句总评"
}`;

async function review(content) {
  const user = `审核以下 ${content.exam}(${content.cefr})口语跟读话题。\n\n内容(JSON):\n${JSON.stringify(content, null, 2)}\n\n${schema}`;
  const body = JSON.stringify({
    model: MODEL,
    messages: [{ role: 'system', content: SYS }, { role: 'user', content: user }],
    temperature: 0.0, max_tokens: 32000, response_format: { type: 'json_object' }, stream: false,
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
    return { parsed: JSON.parse(raw), usage: d.usage };
  } catch (e) { return { error: e.message }; }
  finally { clearTimeout(to); }
}

const all = JSON.parse(readFileSync(SCENES, 'utf8'));
let ids = process.argv.slice(2);
if (ids[0] === '--all-cambridge') ids = all.scenes.filter(s => s.track === 'cambridge').map(s => s.id);

async function run(id) {
  const sc = all.scenes.find(s => s.id === id);
  if (!sc) { console.log('skip(missing)', id); return; }
  const t0 = Date.now();
  const res = await review(contentOf(sc));
  const secs = ((Date.now() - t0) / 1000).toFixed(0);
  if (res.error) { console.log(`✗ ${id} (${secs}s) ERROR ${res.error}`); return; }
  writeFileSync(`${OUT}/${id}.deepseek.json`, JSON.stringify(res.parsed, null, 2));
  const nIss = (res.parsed.issues || []).length;
  console.log(`✓ ${id} (${secs}s) verdict=${res.parsed.verdict} issues=${nIss} tok=${res.usage?.total_tokens || '?'}`);
}

// 并发 4
const CONC = 4; const queue = [...ids];
await Promise.all(Array.from({ length: Math.min(CONC, queue.length) }, async () => {
  while (queue.length) await run(queue.shift());
}));
console.log('DONE', ids.length, '话题');
