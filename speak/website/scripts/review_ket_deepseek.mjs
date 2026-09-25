// DeepSeek v4pro 双卡审核 KET 话题(A2):卡①地道/A2自然度 卡②难度不超纲+KET生活对话考风。
// 用法: node review_ket_deepseek.mjs <content.json>
import { readFileSync, writeFileSync } from 'node:fs';
const LEXENV = '/Users/gelili/Documents/Claude.English/Lexile/.env';
const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/ket-topics-batch1.json';
function readKey(p){const ls=readFileSync(p,'utf8').split('\n');for(const l of ls){const t=l.trim();if(t.startsWith('DEEPSEEK_QA_API_KEY='))return t.slice(20).replace(/^"|"$/g,'');}for(const l of ls){const t=l.trim();if(t.startsWith('DEEPSEEK_API_KEY='))return t.slice(17).replace(/^"|"$/g,'');}return null;}
const KEY=readKey(LEXENV); if(!KEY){console.error('未读到 DEEPSEEK key');process.exit(1);}
const content=JSON.parse(readFileSync(CONTENT,'utf8'));
const sents=[];
for(const [tid,topic] of Object.entries(content)){ if(tid.startsWith('_'))continue;
  (topic.dialogue||[]).forEach((s,i)=>sents.push({tid,idx:i+1,en:s.en,role:s.voice==='chris'?'♂男':'♀女'})); }
const sys=`你是剑桥 KET(A2 Key) 口语考官兼母语审校。审核一套 KET 话题的一男一女生活对话(每话题8句,4组问答)。两道卡:
卡①地道性:是否母语者自然口语?有无中式英语、生硬、不像小孩/青少年说的话?
卡②难度&考风:是否 A2(简单句、日常词、现在时为主,不能出现 B1/B2 难词难句)?对话是否像 KET 的真实生活话题、自然互动?
逐句评估,只把真有问题的标 fix。fix 给改进英文,保持 A2 简单、口语、原意。
输出严格 JSON(无多余文字):{"reviews":[{"tid":"话题id","idx":N,"verdict":"ok/fix","issue":"问题(中文)","suggest":"改进英文"}],"overall":"一句话总评(中文)"}`;
const user=sents.map(s=>`[${s.tid}#${s.idx}·${s.role}] ${s.en}`).join('\n');
console.log(`v4pro 双卡审核 ${sents.length} 句 KET 内容...(约2分钟)`);
const ctrl=new AbortController(); const to=setTimeout(()=>ctrl.abort(),240000);
try{
  const r=await fetch('https://api.deepseek.com/chat/completions',{method:'POST',signal:ctrl.signal,
    headers:{Authorization:`Bearer ${KEY}`,'Content-Type':'application/json'},
    body:JSON.stringify({model:'deepseek-reasoner',messages:[{role:'system',content:sys},{role:'user',content:user}],max_tokens:32000,stream:false})});
  if(!r.ok){console.error('HTTP',r.status,(await r.text()).slice(0,200));process.exit(1);}
  const d=await r.json(); const text=d.choices[0].message.content; const m=text.match(/\{[\s\S]*\}/);
  if(!m){console.error('未解析JSON:',text.slice(0,400));process.exit(1);}
  const out=JSON.parse(m[0]);
  writeFileSync(CONTENT.replace(/\.json$/,'-review.json'),JSON.stringify(out,null,2)+'\n');
  const fixes=(out.reviews||[]).filter(x=>x.verdict==='fix');
  console.log(`\n总评: ${out.overall||''}`); console.log(`需修订 ${fixes.length}/${(out.reviews||[]).length} 句:\n`);
  for(const f of fixes){console.log(`  [${f.tid}#${f.idx}]`);console.log(`    问题: ${f.issue}`);console.log(`    建议: ${f.suggest}\n`);}
  if(!fixes.length)console.log('  ✓ 通过双卡');
}finally{clearTimeout(to);}
