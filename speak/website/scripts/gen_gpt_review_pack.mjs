// 生成给 GPT 的 FCE 终审包(markdown):终审 prompt + 6 个新话题完整内容。
// 用户拿到 Codex/ChatGPT 跑,把结果贴回。用法: node gen_gpt_review_pack.mjs
import { readFileSync, writeFileSync } from 'node:fs';
const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const b1 = JSON.parse(readFileSync(`${ROOT}/_content-drafts/fce-topics-batch1.json`, 'utf8'));
const b2 = JSON.parse(readFileSync(`${ROOT}/_content-drafts/fce-topics-batch2.json`, 'utf8'));

const PROMPT = `你是资深剑桥 **FCE (B2 First Certificate)** 口语考官兼命题专家,熟悉 Cambridge English 官方口语题库与评分标准。

下面是为「FCE 口语跟读备考 App」新编的 **6 个话题**,每个含 Part 1(考官问 + 考生答)和 Part 2(考生看图独白),已经过母语审校(DeepSeek 双卡:地道性 + 语法)。现在请你做**最终把关**,只聚焦两件事:

## 终审一 · 难度是否精准匹配 B2
- 每句是否精准落在 **B2**?有没有偏易(像 A2/B1)或偏难(像 C1)的句子?
- 考生答句是否展现 B2 应有的语言范围(从句、衔接、观点 + 理由 + 例子)?不能太短太简单。
- Part 2 独白是否达到 B2 的连贯度与词汇丰富度?

## 终审二 · 是否全真模拟 FCE 考试
- 考官问句是否和真实 FCE Part 1 的问法、语气、话题一致?
- 考生答句的长度与深度是否符合真实考场的**理想回答**?
- Part 2 是否符合 FCE「对比两张照片」的真实任务(描述 + 推测 + 个人观点 + 衔接词)?
- 考法提示(examTip)和万能句型(templates)是否准确、实用、不误导考生?

## 请这样输出
逐话题给出:
1. **难度评级**:B1偏易 / B2达标 / C1偏难(整话题)
2. **需修改的具体句子**:标出 \`[话题id/part/句号]\` + 问题 + 你的建议改法(只列真有问题的)
3. **全真模拟度**:这个话题作为 FCE 备考素材,像不像真考试

最后给**一句总评**:这 6 个话题作为 FCE 口语备考跟读内容,难度与全真模拟度是否合格、还差什么。`;

let md = `# FCE 新话题 · GPT 终审包\n\n> 用法:把下面「终审任务」+「待终审内容」整段复制给 GPT(Codex / ChatGPT),拿到结果贴回给 Claude 修订。\n> 质检流程:Claude 生成 → DeepSeek v4pro 双卡(地道/语法,已过) → **GPT 终审(难度 + 全真模拟,本步)**。\n\n---\n\n## 终审任务(Prompt)\n\n${PROMPT}\n\n---\n\n## 待终审内容(6 话题 · 90 句)\n\n`;

let n = 0;
for (const src of [b1, b2]) {
  for (const [tid, topic] of Object.entries(src)) {
    if (tid.startsWith('_')) continue;
    n++;
    const m = topic.meta;
    md += `### 话题 ${n}:${m.title} — ${m.subtitle}\n\`${tid}\`\n\n`;
    md += `**Part 1 · 考官问 / 考生答**\n\n`;
    topic.part1.forEach((s, i) => {
      const who = s.voice === 'chris' ? '考生答' : '考官问';
      md += `${i + 1}. \`[${who}]\` ${s.en}\n   > ${s.zh}\n`;
    });
    md += `\n**Part 2 · 考生看图独白**\n\n`;
    topic.part2.forEach((s, i) => { md += `${i + 1}. ${s.en}\n   > ${s.zh}\n`; });
    md += `\n**考法提示**:${m.examTip}\n\n`;
    md += `**万能句型**:\n`;
    m.templates.forEach(t => { md += `- \`${t.en}\` — ${t.zh}\n`; });
    md += `\n---\n\n`;
  }
}

const out = `${ROOT}/_content-drafts/GPT-FCE-终审包.md`;
writeFileSync(out, md);
console.log('已生成终审包:', out);
console.log(`包含 ${n} 话题, ${md.length} 字符`);
