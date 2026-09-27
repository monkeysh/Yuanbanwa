// 剑桥场景元数据修正:已有 Part 3 讨论档的场景,examPart 从「Part 1 + Part 2」补成「Part 1 + Part 2 + Part 3」,
// description 末尾补「+ Part 3 讨论」。Web 芯片(index.html)与 iOS 详情页都显示 examPart,之前少了 Part 3。
// 只改元数据,不碰句子 / id / 音频。幂等。用法(在 speak/website 下):node scripts/normalize_cambridge_parts.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCENES = path.join(ROOT, 'scenes.json');
const raw = readFileSync(SCENES, 'utf8');
const data = JSON.parse(raw);
if (JSON.stringify(data, null, 2) + '\n' !== raw) { console.error('❌ scenes.json 不是标准 2 空格格式,拒绝改写'); process.exit(1); }

let changed = 0;
for (const s of data.scenes) {
  if (s.track !== 'cambridge') continue;
  if (!(s.tiers || []).some(t => t.level === 'part3')) continue;
  let hit = false;
  if (s.examPart === 'Part 1 + Part 2') { s.examPart = 'Part 1 + Part 2 + Part 3'; hit = true; }
  if (typeof s.description === 'string' && !s.description.includes('Part 3')) { s.description += ' + Part 3 讨论'; hit = true; }
  if (hit) { changed++; console.log(`~ ${s.id}: examPart=${s.examPart}`); }
}
if (!changed) { console.log('无需修改。'); process.exit(0); }
writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
console.log(`✓ 修正 ${changed} 个场景的 examPart / description`);
