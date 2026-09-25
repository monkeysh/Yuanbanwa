// 应用 GPT 终审对 KET 6 话题的修正 → 改 _content-drafts/ket-content-new.json
// 按 id 定位 + 句子索引替换 + 原文关键词断言(防索引错位),跑完打印每处 before→after。
import { readFileSync, writeFileSync } from 'node:fs';
const F = '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/ket-content-new.json';
const data = JSON.parse(readFileSync(F, 'utf8'));
const byId = Object.fromEntries(data.map(o => [o.id, o]));
const log = [];

const setExamTip = (id, text) => { const o = byId[id]; log.push(`[${id}] examTip 替换 (${o.examTip.length}→${text.length}字)`); o.examTip = text; };
const setTemplates = (id, tpls) => { byId[id].templates = tpls; log.push(`[${id}] templates 替换 → ${tpls.map(t => t.en).join(' | ')}`); };
const setSentence = (id, idx, { en, zh, expectEn }) => {
  const s = byId[id].sentences[idx];
  if (expectEn && !s.en.includes(expectEn)) throw new Error(`✗ ${id}[${idx}] 原文不含 "${expectEn}"，实际 "${s.en}" —— 索引错位，中止！`);
  const before = `${s.en} 〔${s.zh}〕`;
  if (en !== undefined) s.en = en;
  if (zh !== undefined) s.zh = zh;
  log.push(`[${id}][句${idx + 1}] ${before}\n            → ${s.en} 〔${s.zh}〕`);
};

// ── ket-daily：examTip 归 Part 1 + templates/句5 统一 at weekends ──
setExamTip('ket-daily', `**考法** 在 A2 Key / KET 口语中，"日常作息"常出现在 Part 1 的个人信息问答中，考官可能会问 "What time do you get up?" "How do you go to school?" 或 "What do you do at weekends?"。这段是生活对话拓展，不是真实 Speaking Part 1 考场流程。真实 Part 1 是考官问、考生答，不是两个学生互相采访。
**掌握** 需掌握的核心 A2 句型/词汇：What time...? / I usually... / I walk to school / I go to school by... / At weekends, I... / like doing / so I can... / get up, go to bed, have breakfast。
**注意** 回答时使用完整短句，如 "I get up at 7 o'clock."，不要只说 "7 o'clock."，这样更符合 KET 口语中的完整回答要求。`);
setTemplates('ket-daily', [
  { en: 'What time do you usually ___?', zh: '询问日常活动时间' },
  { en: 'I ___ to school.', zh: '描述上学交通方式' },
  { en: 'At weekends, I ___.', zh: '谈论周末活动' },
  { en: 'I go to bed at ___.', zh: '说睡觉时间' },
]);
setSentence('ket-daily', 4, { en: 'At weekends, I sleep late. What about you?', zh: '周末我会睡懒觉。你呢？', expectEn: 'sleep late' });

// ── ket-weather：examTip 删除 Part 3（A2 Key 只有 2 parts）──
setExamTip('ket-weather', `**考法** 天气与季节是 A2 Key / KET 常见生活话题，可能出现在 Part 1 的个人问答中，也可以作为 Part 2 讨论图片或提示时的相关表达。请注意，这段是生活对话拓展，不是真实 Speaking Part 1 考场流程。真实 Part 1 是考官问、考生答，不是两个学生互相聊天。
**掌握** What's the weather like? / It's sunny and warm. / I like spring because... / I can wear... / I love doing... / In summer, I often...
**注意** 回答时用完整短句，比如 "It's raining."，不要只说 "Rain."；可以加一个简单原因，让回答更丰富。`);

// ── ket-health：examTip 去"满分标准" + 句6/7 更自然 ──
setExamTip('ket-health', `**考法** 健康话题在 A2 Key / KET 口语中常出现，比如考官可能会问 "How do you stay healthy?" 或 "What do you do when you're ill?" 这段是生活对话拓展，不是真实 Speaking Part 1 考场流程。真实 Part 1 是考官问、考生答，不是两个学生互相聊天。
**掌握** 核心 A2 句型/词：I've got a… / Do you need to see a doctor? / You should… / What do you do to stay healthy? / I ride my bike… / eat fruit / do exercise / stay healthy
**注意** 回答时尽量用完整短句，比如 "I've got a headache."，不要只说 "Headache."，这样更符合 KET 口语中完整回答的要求。`);
setSentence('ket-health', 5, { en: 'Thanks. What do you do to stay healthy?', zh: '谢谢。你做什么来保持健康？', expectEn: 'always stay healthy' });
setSentence('ket-health', 6, { en: 'I ride my bike every day and eat fruit.', zh: '我每天骑自行车，也吃水果。', expectEn: 'ride my bike' });

// ── ket-home：句2 中文顺 ──
setSentence('ket-home', 1, { zh: '我住在公园附近的一套公寓里。你呢？', expectEn: 'flat near the park' });

// ── ket-animals：template 释义纠错 + 句4/6/7 更自然 ──
setTemplates('ket-animals', [
  { en: "I've got a ___.", zh: '说我有什么宠物' },
  { en: "My pet's name is ___.", zh: '说宠物叫什么' },
  { en: 'My ___ is ___ and ___.', zh: '描述宠物颜色和特征' },
  { en: "I don't have a pet, but I love ___.", zh: '说我没有宠物但喜欢什么动物' },
]);
setSentence('ket-animals', 3, { zh: '她是白色的，有一双大大的蓝眼睛。', expectEn: 'white with big blue eyes' });
setSentence('ket-animals', 5, { en: 'She loves playing with a ball.', expectEn: 'playing with balls' });
setSentence('ket-animals', 6, { en: "I don't have a pet, but I like dogs.", zh: '我没有宠物，但我喜欢狗。', expectEn: "don't have a pet" });

writeFileSync(F, JSON.stringify(data, null, 2));
console.log(log.join('\n'));
console.log(`\n✓ 应用完成，写回 ${F}`);
