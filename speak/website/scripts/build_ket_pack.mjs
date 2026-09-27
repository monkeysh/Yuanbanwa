import { readFileSync, writeFileSync } from 'node:fs';
const SRC = process.argv[2] || '_content-drafts/ket-content-new.json';
const OUT = process.argv[3] || 'docs/新增KET话题-GPT终审pack.md';
const a = JSON.parse(readFileSync(SRC, 'utf8'));
const L = [];
L.push('# 新增 KET 话题 · GPT 终审 pack\n');
L.push(`> 这 ${a.length} 个 KET(A2 Key)口语跟读话题由 **DeepSeek v4pro 生成**,请你(GPT)做终审。产品:Speak 跟读 App「剑桥考试对话」分区,受众=小学到初中低龄学生。KET 结构=**一男一女 8 句自然对话**(非 Part1/Part2),每话题含 examPart 标注、三段 examTip(考法/掌握/注意)、4 个 templates、3 个 learn 学习点。\n`);
L.push('## 请 GPT 做的事\n1. **逐话题挑错**:CEFR **A2** 级别是否名实相符(**别太难**,词汇/语法要在 A2 范围;也别太幼稚);英文是否地道口语、无语法搭配错;中文翻译是否准确、口语化、一致。\n2. **对话自然度**:8 句是否像真人一问一答、上下衔接、围绕主题层层展开(不是硬凑的孤立句);男女交替是否合理。\n3. **examTip 准确**:三段(考法/掌握/注意)是否准确、有教学价值、无误导。\n4. **templates** 是否 A2 合适、可迁移。\n5. 指出要改的,给**可直接替换**的修正文案。\n');
L.push('## ⚠️ KET 铁律(务必核对,别踩老坑)\n- **examPart 用「话题拓展｜xxx」,绝不标「Part 1」**:KET 真实 Speaking Part 1 是考官问、考生答的考场流程,这里是**生活对话拓展**(两个学生对聊),不能冒充真实 Part 1 流程。\n- **examTip 必须点明「这段不是真实 Speaking Part 1 考场流程,真实 Part 1 是考官问、考生答」**——请确认每条都有、且表述准确。\n- 对话是两个孩子互相问答(可互相反问),这是**拓展练习**的设定,与真实考场"只答考官"不同,examTip 已说明即可,对话本身保留互问形式。\n');
L.push('## 话题全文\n');
for (const t of a) {
  L.push(`### ${t.id}（${t.title} · ${t.subtitle}）`);
  L.push(`- topicKey: \`${t.topicKey}\` ｜ description: ${t.description}`);
  L.push(`- learn: ${(t.learn || []).join(' / ')}`);
  L.push(`- examPart: \`${t.examPart}\``);
  L.push(`- examTip: ${t.examTip.replace(/\n/g, ' ⏎ ')}`);
  L.push(`- templates: ${t.templates.map(x => `\`${x.en}\`(${x.zh})`).join(' / ')}`);
  L.push('- 对话(♂=男声/♀=女声):');
  t.sentences.forEach((s, i) => L.push(`  ${i + 1}. ${s.male ? '♂' : '♀'} ${s.en}  〔${s.zh}〕`));
  L.push('');
}
writeFileSync(OUT, L.join('\n'));
console.log('GPT pack →', OUT, '|', L.join('\n').length, '字符');
