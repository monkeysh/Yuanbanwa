// 可靠补全 rosie 键:parse 遍历每个场景的所有句子对象(顶层 sentences + 各 tier sentences),
// 凡 audio.bella 对应的 rosie 文件已存在,就补 audio.rosie。修复 raw.replace 首匹配漏注入的句子。
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
const ROOT = '/Users/gelili/Documents/Claude.English/Speak-website';
const SCENES = `${ROOT}/scenes.json`;
const a = JSON.parse(readFileSync(SCENES, 'utf8'));
let added = 0, already = 0, noFile = 0, total = 0;
for (const sc of a.scenes) {
  const groups = [sc.sentences || [], ...(sc.tiers || []).map(t => t.sentences || [])];
  for (const arr of groups) for (const se of arr) {
    if (!se.audio || !se.audio.bella) continue;
    total++;
    const base = se.audio.bella.split('/').pop().replace(/\.mp3$/, '');
    if (se.audio.rosie) { already++; continue; }
    if (!existsSync(`${ROOT}/audio/rosie/${base}.mp3`)) { noFile++; continue; }
    se.audio.rosie = `rosie/${base}.mp3`;
    added++;
  }
}
writeFileSync(SCENES, JSON.stringify(a, null, 2));
console.log(`句子对象 ${total} | 新补 rosie 键 ${added} | 已有 ${already} | 无文件跳过 ${noFile}`);
// 复核运行时(tiers)选路
const b = JSON.parse(readFileSync(SCENES, 'utf8'));
const ORDER = ['rosie', 'bella', 'alice', 'chris', 'george'];
const pick = s => { for (const v of ORDER) if (s.audio && s.audio[v]) return v; };
let dR = 0, dT = 0, cR = 0, cT = 0;
for (const s of b.scenes) for (const t of (s.tiers && s.tiers.length ? s.tiers : [{ sentences: s.sentences }])) for (const se of (t.sentences || [])) {
  const daily = (s.track || 'daily') === 'daily';
  if (daily) { dT++; if (pick(se) === 'rosie') dR++; } else { cT++; if (pick(se) === 'rosie') cR++; }
}
console.log(`运行时选路 → 日常 ${dR}/${dT} | 剑桥 ${cR}/${cT} | 全站非Rosie残留 ${(dT - dR) + (cT - cR)} 句`);
