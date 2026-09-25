import { readFileSync, writeFileSync } from 'node:fs';
const SRC = process.argv[2] || '_content-drafts/pet-content-new.json';
const OUT = process.argv[3] || 'docs/新增PET话题-GPT终审pack.md';
const a = JSON.parse(readFileSync(SRC, 'utf8'));
const L = [];
L.push('# 新增 PET 话题 · GPT 终审 pack\n');
L.push(`> 这 ${a.length} 个 PET(B1 Preliminary)口语跟读话题由 **DeepSeek v4pro 生成**,请你(GPT)做终审。产品:Speak 跟读 App「剑桥考试对话」分区,每话题含 examPart 标注、examTip 考点、templates 答题模板、Part 1 面试对话、Part 2 单图描述长独白。\n`);
L.push('## 请 GPT 做的事\n1. **逐话题挑错**:CEFR **B1** 级别是否名实相符(别太难/太易);英文是否地道自然、无语法搭配错;中文翻译是否准确一致。\n2. **考法准确**:examPart 标「Part 1 + Part 2」—— 确认 PET 单图描述确实是 **Part 2**(不是 Part 3);examTip 是否准确、无误导。\n3. **templates** 是否可迁移、B1 合适。\n4. 指出要改的,给**可直接替换**的修正文案。\n');
L.push('## 已知注意点(上批审稿教训)\n- PET 口语官方编号:Part1 面试 / **Part2 单图长说** / Part3 协商 / Part4 讨论。**单图描述=Part2 是对的,别改成 Part3**。\n- examTip 别用「要求用某结构」式绝对措辞,用「通常会自然用到」。\n- PET Part1 本就是考官面试问答,不存在 KET 那种"把生活对话误标 Part1"的问题。\n');
L.push('## 话题全文\n');
for (const t of a) {
  L.push(`### ${t.id}（${t.title} · ${t.subtitle}）`);
  L.push(`- examPart: \`${t.examPart}\``);
  L.push(`- examTip: ${t.examTip}`);
  L.push(`- templates: ${t.templates.map(x => `\`${x.en}\`(${x.zh})`).join(' / ')}`);
  L.push('- Part1:');
  t.part1.forEach((s, i) => L.push(`  ${i + 1}. ${s.en}  〔${s.zh}〕`));
  L.push(`- Part2（${t.part2.prompt}）:`);
  t.part2.sentences.forEach((s, i) => L.push(`  ${i + 1}. ${s.en}  〔${s.zh}〕`));
  L.push('');
}
writeFileSync(OUT, L.join('\n'));
console.log('GPT pack →', OUT, '|', L.join('\n').length, '字符');
