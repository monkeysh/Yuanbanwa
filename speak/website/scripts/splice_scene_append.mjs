// 往现有场景的现有档 append 句子(不新建档)——用于给厚场景深挖增补。
// 句 id/legacyId 接续现有编号;audio basename 用 _add{n} 后缀避免和现有冲突。
// 用法: node splice_scene_append.mjs <content.json>
import { readFileSync, writeFileSync } from 'node:fs';

const CONTENT = process.argv[2];
if (!CONTENT) { console.error('用法: node splice_scene_append.mjs <content.json>'); process.exit(1); }
const SCENES = '/Users/gelili/Documents/Claude.English/Speak-website/scenes.json';

const tokenize = en => en.split(/\s+/)
  .map(w => w.replace(/^[^A-Za-z0-9']+/, '').replace(/[^A-Za-z0-9']+$/, ''))
  .filter(Boolean);

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const data = JSON.parse(readFileSync(SCENES, 'utf8'));
const seenIds = new Set(data.scenes.flatMap(s => (s.tiers || []).flatMap(t => (t.sentences || []).map(x => x.id))));

let added = 0;
const burnList = [];
for (const [sceneId, tiersContent] of Object.entries(content)) {
  if (sceneId.startsWith('_')) continue;
  const scene = data.scenes.find(s => s.id === sceneId);
  if (!scene) { console.error('❌ 场景不存在:', sceneId); process.exit(1); }
  for (const [level, sents] of Object.entries(tiersContent)) {
    const tier = scene.tiers.find(t => t.level === level);
    if (!tier) { console.error(`❌ 档不存在(append 只往现有档加): ${sceneId}/${level}`); process.exit(1); }
    const base = tier.sentences.length;
    sents.forEach((s, i) => {
      const n = base + i + 1;
      const id = `${sceneId}-${level}-${n}`;
      if (seenIds.has(id)) { console.error('❌ 句 ID 冲突:', id); process.exit(1); }
      seenIds.add(id);
      const bname = `${sceneId}_${level}_add${i + 1}`;
      burnList.push({ base: bname, text: s.en });
      tier.sentences.push({ id, legacyIds: [`${level}-${n}`], en: s.en, zh: s.zh, words: tokenize(s.en), weak: [], audio: { rosie: `rosie/${bname}.mp3` } });
      added++;
    });
    tier.sentenceCount = tier.sentences.length;
  }
  scene.sentenceCount = scene.tiers.reduce((sum, t) => sum + t.sentences.length, 0);
}

try { JSON.parse(JSON.stringify(data)); } catch (e) { console.error('非法 JSON:', e.message); process.exit(1); }
writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
writeFileSync(CONTENT.replace(/\.json$/, '-burn.json'), JSON.stringify(burnList, null, 2) + '\n');
console.log(`✓ append ${added} 句;烧音频清单 ${burnList.length} 条`);
console.log(`下一步: node scripts/burn_daily_audio.mjs ${CONTENT.replace(/\.json$/, '-burn.json')}`);
