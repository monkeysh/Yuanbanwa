// 生成 GPT 终审 pack(markdown):内容 + DeepSeek二审/Opus对抗复审结论 + 开放问题,供贴 ChatGPT 终审。
import { readFileSync, writeFileSync } from 'node:fs';
const SCR = '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/review';
const OUTMD = '/Users/gelili/Documents/Claude.English/Speak-website/docs/剑桥口语内容-GPT终审pack.md';
const res = JSON.parse(readFileSync(`${SCR}/REPORT.json`, 'utf8'));
const r = res.report || {};
const perTopic = res.perTopic || [];
const bundle = id => JSON.parse(readFileSync(`${SCR}/bundle/${id}.json`, 'utf8'));

const L = [];
L.push('# 剑桥口语跟读内容 · GPT 终审 pack\n');
L.push('> 审稿链:**DeepSeek v4pro 二审 → Opus 4.8 对抗式复审(独立复审 + 逐条核验 DeepSeek)→ 你(GPT)终审**。');
L.push('> 产品:Speak 跟读 App「剑桥考试对话」分区,KET(A2)/PET(B1)/FCE(B2)各 6 话题,每话题含 examPart 标注、examTip 考点说明、templates 答题模板、Part 1 对话、Part 2 长独白(PET 单图/FCE 双图)。\n');
L.push('## 请 GPT 做的事\n1. 对下方 **7 个开放问题**逐条给出明确裁决与理由(尤其问题 1 的统一定性)。\n2. 复核 Opus 列出的 **4 条 high / 5 条 med** 修正是否准确、修正文案是否最优,若有更好改法请直接给出。\n3. 指出 Opus + DeepSeek 都漏掉的任何**事实性/考法性错误**(剑桥官方 KET/PET/FCE 口语题型编号与流程)。\n');

L.push('## 总体结论(Opus)\n' + (r.overall || '') + '\n');
if (r.levelAssessment) {
  L.push('### 分级评估');
  for (const k of ['KET', 'PET', 'FCE']) L.push(`- **${k}**:${r.levelAssessment[k] || ''}`);
  L.push('');
}
const st = r.stats || {};
L.push(`### 统计\n问题总数 ${st.total ?? '?'}(high ${st.high ?? '?'} / med ${st.med ?? '?'} / low ${st.low ?? '?'})\n`);

L.push('## 开放问题(需 GPT 裁决)\n');
(r.gptQuestions || []).forEach((q, i) => L.push(`**Q${i + 1}.** ${q}\n`));

const fixes = r.prioritizedFixes || [];
const sev = s => fixes.filter(f => f.severity === s);
for (const [lab, key] of [['HIGH(阻断上线)', 'high'], ['MED(建议修)', 'med']]) {
  L.push(`## ${lab} 修正项\n`);
  for (const f of sev(key)) {
    L.push(`### [${f.id}] ${f.field}  · source=${f.source || '?'} conf=${f.confidence ?? '?'}`);
    L.push(`- **问题**:${f.problem}`);
    L.push(`- **建议修正**:${f.fix}\n`);
  }
}

// 附:受影响话题全文(KET 全部 + pet-school),供 GPT 判定
const affected = ['ket-personal', 'ket-shopping', 'ket-food', 'ket-travel', 'ket-school', 'ket-hobbies', 'pet-school'];
L.push('## 附录:受影响话题全文(供 GPT 判定)\n');
for (const id of affected) {
  const b = bundle(id); const c = b.content;
  L.push(`### ${id}（${c.exam}/${c.cefr}）${c.title} — ${c.subtitle}`);
  L.push(`- examPart: \`${c.examPart}\``);
  L.push(`- examTip: ${c.examTip}`);
  L.push(`- templates: ${c.templates.map(t => `\`${t.en}\`(${t.zh})`).join(' / ')}`);
  L.push(`- Part1:`);
  c.part1.forEach((s, i) => L.push(`  ${i + 1}. ${s.en}  〔${s.zh}〕`));
  if (c.part2) { L.push(`- Part2:`); c.part2.sentences.forEach((s, i) => L.push(`  ${i + 1}. ${s.en}  〔${s.zh}〕`)); }
  L.push('');
}

writeFileSync(OUTMD, L.join('\n'));
console.log('GPT 终审 pack →', OUTMD);
console.log('字数约', L.join('\n').length, '字符');
