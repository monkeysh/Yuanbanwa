// KET Part2 v4pro 双卡审核(按官方 A2 Key Part2 题型)。用法: node review_ket_part2.mjs <content.json>
import { readFileSync, writeFileSync } from 'node:fs';
const CONTENT=process.argv[2];
function readKey(p){const L=readFileSync(p,'utf8').split('\n');
 for(const l of L){const t=l.trim();if(t.startsWith('DEEPSEEK_QA_API_KEY='))return t.slice(20).replace(/^"|"$/g,'');}
 for(const l of L){const t=l.trim();if(t.startsWith('DEEPSEEK_API_KEY='))return t.slice(17).replace(/^"|"$/g,'');}return null;}
const KEY=readKey('/Users/gelili/Documents/Claude.English/Lexile/.env');
const c=JSON.parse(readFileSync(CONTENT,'utf8'));
const sents=[];
for(const [tid,t] of Object.entries(c)){ if(tid.startsWith('_'))continue;
  t.part2.forEach((s,i)=>sents.push({tid,idx:i+1,en:s.en,who:s.voice==='chris'?'考生B':'考生A'})); }
const sys=`你是剑桥 KET(A2 Key) 口语考官,熟悉官方 handbook。审核 A2 Key Speaking Part 2 跟读内容。
官方题型:两名考生看5幅同主题图,各自谈喜欢/不喜欢+原因,互相回应,**不要求达成一致**;不是共同决定/角色扮演。
两道卡:①地道性(母语青少年自然说法?中式英语/语法错?)②难度与题型(精准A2?符合官方Part2?五幅图是否都自然谈到?有无套路化开头/机械收尾?)
逐句评估,只标真有问题的fix。输出严格JSON:{"reviews":[{"tid":"话题id","idx":N,"verdict":"ok/fix","issue":"问题","suggest":"改进英文"}],"typeVerdict":"题型判定(中文一句)","overall":"总评(中文一句)"}`;
const user=sents.map(s=>`[${s.tid}#${s.idx}·${s.who}] ${s.en}`).join('\n');
console.log(`v4pro 双卡审核 ${sents.length} 句...`);
const r=await fetch('https://api.deepseek.com/chat/completions',{method:'POST',
 headers:{Authorization:`Bearer ${KEY}`,'Content-Type':'application/json'},
 body:JSON.stringify({model:'deepseek-reasoner',messages:[{role:'system',content:sys},{role:'user',content:user}],max_tokens:32000,stream:false})});
const d=await r.json();
const m=d.choices[0].message.content.match(/\{[\s\S]*\}/);
const out=JSON.parse(m[0]);
writeFileSync(CONTENT.replace(/\.json$/,'-review-v2.json'), JSON.stringify(out,null,2)+'\n');
console.log(`\n【题型】${out.typeVerdict}\n【总评】${out.overall}`);
const fixes=(out.reviews||[]).filter(x=>x.verdict==='fix');
console.log(`\n需修订 ${fixes.length} 句:\n`);
for(const f of fixes) console.log(`  [${f.tid}#${f.idx}] ${f.issue}\n    → ${f.suggest}\n`);
if(!fixes.length) console.log('  ✓ 无需修订');
