// 给现有 daily 场景补 entry/intermediate/advanced 三档(初级 beginner 不动)。
// 单人跟读:audio 只放 rosie。tier 按 入门/初级/中级/高级 排序。
// scenes.json 是标准 2 空格 JSON(已验证 parse+stringify 零差异),直接改。
// 同时产出烧音频清单 *-burn.json 供 burn_daily_audio.mjs 使用。
// 用法: node splice_daily_expand.mjs [content.json]
import { readFileSync, writeFileSync } from 'node:fs';

const CONTENT = process.argv[2] || '/Users/gelili/Documents/Claude.English/Speak-website/_content-drafts/daily-expand-batch1.json';
const SCENES = '/Users/gelili/Documents/Claude.English/Speak-website/scenes.json';

const LABELS = { entry: '入门', beginner: '初级', intermediate: '中级', advanced: '高级' };
const ORDER = ['entry', 'beginner', 'intermediate', 'advanced'];
// 展示 token:去首尾非字母数字撇号,词中撇号保留(don't/I'm),纯符号(—)过滤掉。
const tokenize = en => en.split(/\s+/)
  .map(w => w.replace(/^[^A-Za-z0-9']+/, '').replace(/[^A-Za-z0-9']+$/, ''))
  .filter(Boolean);

const content = JSON.parse(readFileSync(CONTENT, 'utf8'));
const data = JSON.parse(readFileSync(SCENES, 'utf8'));

let addedTiers = 0, addedSents = 0;
const burnList = [];
const seenIds = new Set(data.scenes.flatMap(s => (s.tiers || []).flatMap(t => (t.sentences || []).map(x => x.id))));

for (const [sceneId, tiersContent] of Object.entries(content)) {
  if (sceneId.startsWith('_')) continue;
  const scene = data.scenes.find(s => s.id === sceneId);
  if (!scene) { console.error('❌ 场景不存在:', sceneId); process.exit(1); }

  const byLevel = {};
  for (const t of scene.tiers) byLevel[t.level] = t;

  for (const [level, sents] of Object.entries(tiersContent)) {
    if (byLevel[level]) { console.log(`跳过已存在 ${sceneId}/${level}`); continue; }
    const tierSents = sents.map((s, i) => {
      const base = `${sceneId}_${level}_${i + 1}`;
      const id = `${sceneId}-${level}-${i + 1}`;
      if (seenIds.has(id)) { console.error('❌ 句 ID 冲突:', id); process.exit(1); }
      seenIds.add(id);
      burnList.push({ base, text: s.en });
      return { id, legacyIds: [`${level}-${i + 1}`], en: s.en, zh: s.zh, words: tokenize(s.en), weak: [], audio: { rosie: `rosie/${base}.mp3` } };
    });
    byLevel[level] = { level, label: LABELS[level], sentenceCount: tierSents.length, sentences: tierSents };
    addedTiers++; addedSents += tierSents.length;
  }
  scene.tiers = ORDER.filter(l => byLevel[l]).map(l => byLevel[l]);
  scene.sentenceCount = scene.tiers.reduce((n, t) => n + t.sentences.length, 0);
}

try { JSON.parse(JSON.stringify(data)); } catch (e) { console.error('非法 JSON:', e.message); process.exit(1); }
writeFileSync(SCENES, JSON.stringify(data, null, 2) + '\n');
writeFileSync(CONTENT.replace(/\.json$/, '-burn.json'), JSON.stringify(burnList, null, 2) + '\n');
console.log(`✓ 新增 ${addedTiers} 档 / ${addedSents} 句`);
console.log(`✓ 烧音频清单 ${burnList.length} 条 → ${CONTENT.replace(/\.json$/, '-burn.json')}`);
console.log(`下一步: node scripts/burn_daily_audio.mjs`);
