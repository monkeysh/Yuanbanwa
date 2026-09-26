#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (file) => fs.readFileSync(path.join(ROOT, file), 'utf8');
const fail = (message) => {
  throw new Error(message);
};

const data = JSON.parse(read('scenes.json'));
const sceneIds = new Set();
const globalSentenceIds = new Set();
let sentenceCount = 0;
let rosieCount = 0;
let chrisCount = 0;
// audio/ 不进版本库（见 .gitignore）。只有显式设置 SPEAK_ALLOW_MISSING_AUDIO=1 的开发环境
// （例如 Claude Code 云端会话）才把“音频文件不存在”降级为警告；默认仍然严格失败。
const ALLOW_MISSING_AUDIO = process.env.SPEAK_ALLOW_MISSING_AUDIO === '1';
let missingAudioCount = 0;

for (const scene of data.scenes || []) {
  if (!scene.id) fail('发现缺少 id 的场景');
  if (sceneIds.has(scene.id)) fail(`场景 id 重复：${scene.id}`);
  sceneIds.add(scene.id);

  const tiers = scene.tiers || [];
  if (!tiers.length) fail(`场景缺少 tiers：${scene.id}`);

  for (const tier of tiers) {
    if (!Array.isArray(tier.sentences) || !tier.sentences.length) {
      fail(`档位缺少句子：${scene.id}/${tier.level || 'unknown'}`);
    }
    const tierSentenceIds = new Set();
    const legacyIds = new Set();

    for (const [index, sentence] of tier.sentences.entries()) {
      sentenceCount += 1;
      const label = `${scene.id}/${tier.level}/${index + 1}`;
      if (typeof sentence.id !== 'string' || !sentence.id.trim()) fail(`句子缺少显式 id：${label}`);
      if (tierSentenceIds.has(sentence.id)) fail(`同一场景/档位句子 id 重复：${label} -> ${sentence.id}`);
      if (globalSentenceIds.has(sentence.id)) fail(`全站句子 id 重复：${label} -> ${sentence.id}`);
      tierSentenceIds.add(sentence.id);
      globalSentenceIds.add(sentence.id);
      if (!Array.isArray(sentence.legacyIds) || !sentence.legacyIds.length) {
        fail(`句子缺少旧位置 ID 迁移信息：${label}`);
      }
      for (const legacyId of sentence.legacyIds) {
        if (typeof legacyId !== 'string' || !legacyId) fail(`句子 legacyIds 非法：${label}`);
        if (legacyIds.has(legacyId)) fail(`同一场景/档位 legacyId 重复：${label} -> ${legacyId}`);
        legacyIds.add(legacyId);
      }
      if (!sentence.en || !sentence.zh) fail(`句子缺少中英文：${label}`);
      if (!Array.isArray(sentence.words) || !sentence.words.length) fail(`句子缺少 words：${label}`);
      if (!Array.isArray(sentence.weak)) fail(`句子缺少 weak：${label}`);
      for (const weakIndex of sentence.weak) {
        if (!Number.isInteger(weakIndex) || weakIndex < 0 || weakIndex >= sentence.words.length) {
          fail(`weak 索引越界：${label} -> ${weakIndex}`);
        }
      }

      const preferredVoice = sentence.voice || 'rosie';
      const audioPath = sentence.audio?.[preferredVoice] || sentence.audio?.rosie || sentence.audio?.chris;
      if (!audioPath) fail(`句子没有有效首选音频：${label}`);
      if (!fs.existsSync(path.join(ROOT, 'audio', audioPath))) {
        if (!ALLOW_MISSING_AUDIO) fail(`音频文件不存在：${label} -> audio/${audioPath}`);
        missingAudioCount += 1;
      }
      if (preferredVoice === 'chris') chrisCount += 1;
      else rosieCount += 1;
    }
  }
}

const indexHtml = read('index.html');
for (const [pattern, message] of [
  [/const\s+score\s*=\s*real\s*\?[^;]+:\s*92\b/, '反馈卡仍含固定 92 分'],
  [/\{\s*v:\s*['"]92['"]\s*,\s*l:\s*['"]平均相似度['"]/, '结果页仍含固定 92%'],
  [/连续\s*13\s*天/, '结果页仍含固定连续 13 天'],
  [/ADMIN_IDS\s*=|signInAdmin\s*\(/, '仍存在前端硬编码超管登录'],
  [/setCode\(['"]1234['"]\)/, '仍存在自动填入的伪验证码'],
]) {
  if (pattern.test(indexHtml)) fail(message);
}

for (const file of ['terms.html', 'privacy.html']) {
  if (!fs.existsSync(path.join(ROOT, file))) fail(`缺少生产协议页：${file}`);
}

const matcherStart = indexHtml.indexOf('const CONTRACTIONS =');
const matcherEndMarker = 'function PracticeScreen(';
const matcherEnd = indexHtml.indexOf(matcherEndMarker, matcherStart);
if (matcherStart < 0 || matcherEnd < 0) fail('无法从 index.html 提取 matchWords');

const matcherSource = `${indexHtml.slice(matcherStart, matcherEnd)}\nglobalThis.__matchWords = matchWords;`;
const matcherContext = {};
vm.createContext(matcherContext);
vm.runInContext(matcherSource, matcherContext, { timeout: 1000 });
const matchWords = matcherContext.__matchWords;

const exact = matchWords(['Nice', 'to', 'meet', 'you'], 'Nice to meet you');
if (exact.score !== 100 || exact.missed.length) fail('matchWords 精确匹配回归失败');

const contraction = matchWords(["I'm", 'ready'], 'I am ready');
if (contraction.score !== 100 || contraction.missed.length) fail('matchWords 缩写等价回归失败');

const repeatedTarget = ['Could', 'you', 'put', 'the', 'dressing', 'on', 'the', 'side'];
const missingRepeatedWord = matchWords(repeatedTarget, 'Could you put the dressing on side');
if (missingRepeatedWord.score === 100 || !missingRepeatedWord.missed.includes(6)) {
  fail('matchWords 仍会复用已匹配单词：漏读第二个 the 仍被判全对');
}

const progressStart = indexHtml.indexOf("const PROGRESS_KEY =");
const progressEnd = indexHtml.indexOf('function App(', progressStart);
if (progressStart < 0 || progressEnd < 0) fail('无法从 index.html 提取 Progress');
const legacyScene = {
  id: 'legacy-complete',
  tiers: [
    { level: 'beginner', sentences: [
      { id: 'complete-b1', legacyIds: ['beginner-1'], tierLevel: 'beginner' },
      { id: 'complete-b2', legacyIds: ['beginner-2'], tierLevel: 'beginner' },
    ] },
    { level: 'advanced', sentences: [
      { id: 'complete-a1', legacyIds: ['advanced-1'], tierLevel: 'advanced' },
    ] },
  ],
};
const partialScene = {
  id: 'legacy-partial',
  tiers: [{ level: 'beginner', sentences: [
    { id: 'partial-b1', legacyIds: ['beginner-1'], tierLevel: 'beginner' },
    { id: 'partial-b2', legacyIds: ['beginner-2'], tierLevel: 'beginner' },
  ] }],
};
const legacyProgress = {
  reviewQueue: [
    { sceneId: 'legacy-partial', sentIdx: 0, missed: [0] },
    { sceneId: 'legacy-partial', tierLevel: 'beginner', sentenceId: 'beginner-2', missedWords: ['word'] },
  ],
  days: {}, totalSents: 2, scenesDone: ['legacy-complete'],
  sceneCounts: { 'legacy-complete': 1 }, joinedAt: '2026-07-01', lastSceneId: 'legacy-complete',
  completedSentences: { 'legacy-partial': ['beginner::beginner-2'] },
};
let storedProgress = JSON.stringify(legacyProgress);
let migrationWrites = 0;
const progressContext = {
  SCENES: [legacyScene, partialScene],
  localStorage: {
    getItem: () => storedProgress,
    setItem: (_key, value) => { storedProgress = value; migrationWrites += 1; },
  },
  window: { dispatchEvent: () => {} },
  CustomEvent: class {},
};
vm.createContext(progressContext);
vm.runInContext(
  `var SCENES = globalThis.SCENES;\n${indexHtml.slice(progressStart, progressEnd)}\nglobalThis.__Progress = Progress;`,
  progressContext,
  { timeout: 1000 },
);
const migratedProgress = progressContext.__Progress.read();
if (migratedProgress.schemaVersion !== 2 || migrationWrites !== 1) {
  fail('v1 进度没有一次性迁移并写回 schemaVersion=2');
}
if (migratedProgress.completedSentences['legacy-complete']?.length !== 3) {
  fail('v1 scenesDone 没有完整迁移为句级完成记录');
}
if (progressContext.__Progress.sceneProgress(legacyScene, migratedProgress) !== 100) {
  fail('v1 已完成场景迁移后不再保持 100%');
}
if (migratedProgress.completedSentences['legacy-partial']?.[0] !== 'beginner::partial-b2') {
  fail('旧位置 sentenceId 没有迁移到显式句子 ID');
}
const migratedReviewIds = migratedProgress.reviewQueue.map(item => item.sentenceId).sort();
if (migratedReviewIds.join(',') !== 'partial-b1,partial-b2') {
  fail('旧 review sentIdx/sentenceId 没有迁移到显式句子 ID');
}

// 模拟上线后给一个已完成场景新增句子：v2 不得再根据 scenesDone 自动补全。
legacyScene.tiers[0].sentences.push({ id: 'complete-b3-new', legacyIds: [], tierLevel: 'beginner' });
const rereadProgress = progressContext.__Progress.read();
if (migrationWrites !== 1) fail('schemaVersion=2 被重复迁移写回');
if (rereadProgress.completedSentences['legacy-complete']?.length !== 3) {
  fail('新增句子被旧 scenesDone 自动标记完成');
}
if (progressContext.__Progress.sceneProgress(legacyScene, rereadProgress) !== 75) {
  fail('新增句子后完成度没有按显式 ID 正确回落');
}

if (missingAudioCount) {
  console.log(`WARN: SPEAK_ALLOW_MISSING_AUDIO=1，跳过了 ${missingAudioCount} 个缺失音频文件的存在性检查（audio/ 不在版本库中，勿据此部署）`);
}
console.log(`OK: ${sceneIds.size} 个场景，${sentenceCount} 条分档句子，${rosieCount} 条 Rosie + ${chrisCount} 条 Chris 首选音频${missingAudioCount ? '引用完整' : '均有效'}`);
console.log('OK: 假分/伪超管/伪验证码检查通过');
console.log('OK: matchWords 精确、缩写与重复词回归通过');
console.log('OK: v1 进度/复练引用可一次性迁移；新增句子不会自动完成');
