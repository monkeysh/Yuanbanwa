import { readFileSync, writeFileSync } from 'node:fs';
const ROOT='/Users/gelili/Documents/Claude.English/Speak-website';
const c=JSON.parse(readFileSync(`${ROOT}/_content-drafts/ket-topics-batch1.json`,'utf8'));
const PROMPT=`你是资深剑桥 **KET (A2 Key)** 口语考官兼命题专家。下面是为「KET 口语跟读备考 App」新编的 **6 个话题**,每个是一男一女(Tom/Lily)的生活对话(8 句,4 组问答),已过母语审校(DeepSeek 双卡)。请做**最终把关**,只聚焦两点:

## 终审一 · 难度是否精准 A2
- 每句是否落在 **A2**?有没有偏难(出现 B1/B2 难词、复杂从句)?
- 对话是否简单、口语、适合初学者跟读模仿?

## 终审二 · 是否符合 KET 生活对话
- 话题、问法、互动是否像真实 KET?对话是否自然(不生硬、不像教科书造句)?
- 男女说话人分配是否正确、对话逻辑是否通顺?

## 请这样输出
逐话题:①难度评级(A1偏易/A2达标/B1偏难)②需改的具体句子(标\`[话题id#句号]\`+问题+建议)③像不像 KET。最后一句总评:这 6 话题作为 KET 跟读素材是否合格。`;
let md=`# KET 新话题 · GPT 终审包\n\n> 用法:整段复制给 GPT(Codex/ChatGPT),结果贴回 Claude。流程:Claude生成→DeepSeek v4pro双卡(已过,修了1处说话人)→**GPT终审(难度A2+KET全真,本步)**。\n\n---\n\n## 终审任务\n\n${PROMPT}\n\n---\n\n## 待终审内容(6 话题 · 48 句)\n\n`;
let n=0;
for(const [tid,topic] of Object.entries(c)){ if(tid.startsWith('_'))continue; n++;
  const m=topic.meta;
  md+=`### 话题 ${n}:${m.title} — ${m.subtitle}\n\`${tid}\`\n\n`;
  topic.dialogue.forEach((s,i)=>{const who=s.voice==='chris'?'♂Tom':'♀Lily';md+=`${i+1}. \`[${who}]\` ${s.en}\n   > ${s.zh}\n`;});
  md+=`\n**考法**:${m.examTip}\n\n**万能句型**:\n`;
  m.templates.forEach(t=>md+=`- \`${t.en}\` — ${t.zh}\n`);
  md+=`\n---\n\n`;
}
writeFileSync(`${ROOT}/_content-drafts/GPT-KET-终审包.md`,md);
console.log('已生成:',`${n} 话题, ${md.length} 字符`);
