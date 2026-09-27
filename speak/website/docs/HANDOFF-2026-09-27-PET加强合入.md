# Speak 交接 · 2026-09-27 · PET 加强合入

> 上一份:`docs/HANDOFF-2026-09-26-B1B2合入.md`(日常 B1/B2 收口)。方案:`docs/PLAN-2026-09-26-PET加强方案.md`(用户 2026-09-27 拍板「按建议做」)。
> 必读:`docs/PET-官方题型断言-2026-07-31.md`、`docs/日常场景内容生产检查清单-2026-08-16.md`。

## 一句话现状

PET 加强两批已合入 `scenes.json`:**75 → 81 场景,240 → 258 tier,1986 → 2188 句**;PET 12 → 18 话题(507 句)。Web 与 iOS 两份 `scenes.json` md5 相同。**542 个音频文件未烧**(日常 B1/B2 256 + PET Part 2 加长 28 + 新话题 258),**Web 未部署**——两步都等用户点头。

## 本次做了什么

1. **B2 · Part 2 独白加长**(提交 0a0a3e6):12 组各补 1–3 句可见细节,共 28 句,补到 117–129 词;新句插在收尾句之前、id 顺延、rosie 单声;现有句零改动。内容 `_content-drafts/pet-part2-extend.json`,脚本 `scripts/splice_pet_part2_extend.mjs`,自审 `_content-drafts/Claude-PET-Part2加长-自审报告-2026-09-27.md`,终审 pack `docs/PET-Part2加长-终审pack-2026-09-27.md`。
2. **元数据修正**(同一提交):24 个有 Part 3 档的剑桥场景(PET 12 + FCE 12)examPart → `Part 1 + Part 2 + Part 3`,description 补 `+ Part 3 讨论`(Web 芯片与 iOS 详情页显示该字段)。脚本 `scripts/normalize_cambridge_parts.mjs`。
3. **B1 · 6 个新 PET 话题**:pet-personal / pet-home / pet-sports / pet-transport / pet-festivals / pet-friends,每个 Part 1(8)+ Part 2(9,126–132 词)+ Part 3(12)+ 4 模板 + examTip。内容 `_content-drafts/pet-content-batch2.json`,脚本 `scripts/splice_pet_batch2.mjs`(幂等),自审 `_content-drafts/Claude-新增PET话题-第二批-自审报告-2026-09-27.md`,终审 pack `docs/新增PET话题-第二批-终审pack-2026-09-27.md`。
4. 方案里的两项决定已落实:交接 ④「Part 2 搭档 30 秒回应」不做(是 FCE 结构);Part 3 维持「压缩跟读示范」12 句。

## 落地步骤(音频与部署等用户点头)

1. (可选)把两个终审 pack 交 Codex / GPT,结论回填后直接改 `scenes.json` 对应句并同步内容文件(句 id 不变),重跑 `npm run validate`。
2. 烧音频(幂等,已存在的文件跳过):
   ```bash
   cd speak/website
   node scripts/burn_ket_audio.mjs emergency-call car-breakin insurance-claim starbucks hotel-checkout baggage gate customs parent-meeting sick-leave   # 日常 B1/B2,256
   node scripts/burn_ket_audio.mjs pet-daily pet-hobbies pet-travel pet-shopping pet-food pet-school pet-health pet-weather pet-entertainment pet-technology pet-work pet-family   # Part 2 加长,28
   node scripts/burn_ket_audio.mjs pet-personal pet-home pet-sports pet-transport pet-festivals pet-friends   # 新话题,258
   npm run validate   # 不带开关,必须 0 缺失
   ```
3. iOS:`speak/ios/Speak/Resources/scenes.json` 已同步;音频目录同步后 `xcodegen generate`、Xcode 构建、真机验收(新话题三档、加长后的 Part 2、场景芯片显示 Part 3)。
4. Web:`bash deploy-speak.sh --dry-run` 看清单 → 用户授权后部署。

## 避坑(本次新增)

- **复数属格尾撇号**:`grandparents'` 这类词经 tokenize 后会留下尾撇号 token,影响跟读比对;写内容时改用 `grandma's` 一类单数属格,或换说法。合入脚本外的自检:全站 `words` 里不允许首尾撇号(本次已核 0)。
- **Part 3 题材撞车**:既有 24 组 Part 3 里生日题材已有 3 组,新组写之前先列既有开场句(见自审报告第五节的做法)。
- **人名复用**:Anna / Tom / Lily / Jack 等已被既有组占用,新组换名。
- `scripts/splice_cambridge_new.mjs` 已过时(Mac 绝对路径、四声线、只有 Part 1/2),不要再用;PET 新话题走 `splice_pet_batch2.mjs`(改 CONTENT 路径即可复用于下一批)。

## 下一步

1. 终审回填(如做)→ 烧音频 → 真机验收 → 部署。
2. FCE:Part 2 缺「搭档 30 秒 follow-up」是真实缺口(`docs/FCE-官方题型断言-2026-08-02.md` §二),另立批次。
3. S3 发音体检(iOS,ARPABET 音素映射);`phone-call` 接听档补防诈骗话术。

## 下次开场提示(可直接拷贝)

```
继续 Speak(原版娃口语)。先读 speak/website/docs/HANDOFF-2026-09-27-PET加强合入.md,
再读 docs/日常场景内容生产检查清单-2026-08-16.md。
PET 加强已合入(81 场景 / 2188 句,PET 18 话题),542 个音频未烧、Web 未部署——这两步要我点头。
两个终审 pack(PET-Part2加长 / 新增PET话题-第二批)如有回填结论,先按结论修订再烧音频。
```
