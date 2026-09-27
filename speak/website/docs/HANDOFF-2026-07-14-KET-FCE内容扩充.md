# Speak 交接 · 2026-07-14

> 上一份:`docs/HANDOFF-P0-P1-2026-07-11.md`(P0/P1 修复,已过期)

## 一句话现状

Speak 已转为 **iOS 原生主力**(网页降级为引流/试用)。内容 **73 场景 1137 句**(932 Rosie + 205 Chris 真人音频),web 已部署 <https://speak.yuanbanwa.top>;**iOS 侧全部改动本地装机验收中、未提交 git**。三重质检流程(Claude 生成 → DeepSeek v4pro 双卡 → GPT 终审)已跑通并救回一次题型级事故。

---

## 一、产品现在长什么样

| 板块 | 内容 | 功能 |
|---|---|---|
| **日常对话** | 31 场景(含新增「求职面试」) | 跟读 + SOE 真发音评测 |
| **剑桥** | KET 18 / PET 12 / FCE 12 话题 | 跟读 + **AI 模拟考官**(仅剑桥有) |

- **跟读**:点一下录 → 再点一下出分。SOE 音素级评分(发音/准确/流利/完整 + 薄弱词音素)
- **AI 模拟考官**(剑桥专属):DeepSeek 驱动的自由问答,女考官 Rosie / 男考官 Chris(真人头像 + 男女 TTS),8 维度轮转,考后中文报告(内容点评 + **发音分** + 参考范文)
- **声线全站只有 Rosie(女) + Chris(男)**,死链已清

---

## 二、这轮做完的事

### 内容
- **日常 8 场景补齐 4 档**(问路/打车/超市/机场/地铁/外卖/感谢/道歉,6-8句→28-29句)
- **自我介绍深挖** 32→54 句(补学习/家庭/爱好维度)
- **新增「求职面试」**场景(4档22句,v4pro 双卡审)
- **FCE 话题 6→12**(人际关系/教育/理想/生活方式/饮食/金钱,各 Part1×8 + Part2×7 + 剑桥三件套)
- **KET 补 Part 2**(6 话题,按官方题型,10-11句/话题)← 详见下方事故复盘

### 功能/修复
- **模拟考官**:男女考官 + 真人头像 + 男女声 TTS;纯考官人设(代码强制掐夸奖);8 维度轮转;**questionZh 中文提示**(考官问题下方小字)
- **streak 修复**:`AppStore.recordPractice` 此前**从不更新 streakDays**(永远 0),加 `lastPracticeDay` + `updateStreak()`
- 跟读交互:hold-to-talk → **点击切换**;auto-stop 加 `recordSession` 会话号(防旧任务误停新录音);出分反馈卡不再被话筒挤截断
- 声线清理:scenes.json 死链 2028(tiers) + 669(顶层 sentences) 全清;`VoicePreference` 精简为 rosie/chris

---

## 三、三重质检流程(核心方法论)

```
Claude 生成 → DeepSeek v4pro 双卡(地道性/语法) → GPT 终审(难度 + 全真模拟)
```

**工具**:
- `scripts/review_fce_deepseek.mjs` — v4pro 双卡(deepseek-reasoner)
- `scripts/gen_gpt_review_pack.mjs` — 生成 GPT 终审包 md,用户拿去 Codex/ChatGPT 跑,结果贴回

**战果**:
- FCE 6 话题:v4pro 挑 2 处 whereas 生硬;GPT 终审裁定「B2 合格、全真模拟 9.3/10、可上线、语言质量高于普通备考资料」,挑 11 处(2 必改)
- KET Part2:**GPT 抓出题型级事故**(见下),Qwen 补挑套路化

### 🔴 铁律一:审核 prompt 绝不能把"标准"喂给模型

**事故复盘**:我凭臆想把 KET Part2 做成「提方案→比较→共同决定→达成一致」的角色扮演(约时间/定计划/组订单)。v4pro 双卡判"完全符合" —— **不是它不知道,是我在 prompt 里写死了错误标准,它照着我的错尺子量**。

**正确姿势**(三步法,见 `/tmp/review_ket_qwen.mjs` 模式):
1. **先让模型自己交代官方题型**(officialFormat)
2. 再对照判定内容(typeVerdict)
3. 最后审语言难度

验证:Qwen3.7-plus 不给标准,独立说出与 GPT 引 handbook **完全一致**的官方形式。**三个模型都知道,错的是我的 prompt**。

### ⭐ 官方 A2 Key Speaking Part 2 正解

- **Phase 1**:两名考生共看 **5 幅图**,各自谈**喜欢/不喜欢 + 原因**(官方指令 "Do you like these different hobbies? Say why or why not."),回应对方让交流继续,**绝不要求达成一致**(喜好不同很正常)
- **Phase 2**:考官就同一话题分别追问
- 官方明确**建议避免背诵整段套话**
- **不是**决策任务,**不是**角色扮演

### 铁律二:多 AI 互审仍必要(角度不同)

Qwen 对重构版补挑:①缺视觉刺激(媒介限制,跟读 App 无图) ②剧本式非即兴(跟读本质;**即兴由 AI 模拟考官补**) ③**"For me, X is the best" 6话题里5个都这么结尾=套路化**(真问题,已打散) + 6 处逻辑/语气修订。

> 用户英语能力不足,这套多 AI 互审是他唯一的质量防线(原话:"我的英语能力不够做很多检查,只能多次互审核来解决大范围审核")。**模拟考官的 questionZh 中文提示**既是他的验收抓手,也是 KET/PET 学生刚需。

---

## 四、待办(建议优先级)

1. **剩 12 个 KET 话题补 Part 2** — 按官方题型(5图/喜好理由/不求一致),流程和标准都跑通了,不会再翻车
2. **KET/PET 话题扩充** — FCE 做了 6→12,KET(18)/PET(12) 可再扩
3. **考官换真人音频** — 现在是系统合成 TTS,可预烧高频题库 Rosie/Chris
4. **剩 16 个单档日常场景**补齐 4 档(星巴克/过海关/药店/打电话等)
5. **Part 3 题型** / **语法纠错反馈** / **网页版 streak**(iOS 已修,web 未查)
6. **iOS 改动提交 git** — 本会话大量 iOS 改动未版本化(文件在磁盘,无版本记录)

---

## 五、避坑清单

| 坑 | 说明 |
|---|---|
| **Xcode 验证** | Debug 真代码在 `Speak.app/Speak.debug.dylib`(5.5MB),主执行文件只是 91KB 壳 —— **验二进制必须验 dylib**;中文串用 `grep -ac`/python bytes(strings 只提 ASCII 会假阴性);**注释不进二进制,别拿注释当校验串** |
| **xcodegen** | `xcodegen generate` 后必须 `rm -rf build` 全量重建,否则增量构建静默出旧包(BUILD SUCCEEDED 但 0 个 CompileSwift) |
| **git 隔离** | monorepo 根是 git 仓,`git add -A` 会误带所有 sibling(chn/vocab/HuaFM…) —— **必须 `git add Speak-website/`** |
| **audio** | `audio/` 已 gitignore(46MB),deploy-speak.sh 从本地传;iOS 同步用 rsync,**改动句要强制覆盖**(`--ignore-existing` 会漏) |
| **scenes.json** | 标准 2 空格 JSON,`json.dumps(indent=2)+'\n'` 与原文件零差异,可安全 parse+改+写回;**句子必须带 `legacyIds`** 否则 validate 挂;顶层 `sentences` 是遗留字段(transformScenesJSON tiers 优先,根本不渲染) |
| **LLM 不听话** | prompt 明令禁止也会犯(冒夸奖/冒 "What's your name?") —— **不赌自觉,代码兜底**(`sanitizeReaction` 白名单 / `GENERIC_OPENER` 正则打回重问) |
| **模拟考官维度** | VARIANTS 必须是「切入维度」(习惯/经历/喜好/观点/对比/变化/困难/建议),**不能是具体话题**(否则和场景话题打架跳题);每个维度都要能当开场题 |
| **功能型场景** | topic 是「领域」不是「任务」——「Ordering at a café」要问爱吃什么/常去咖啡馆,不能考"点餐难不难" |

---

## 六、常用命令

```bash
cd Speak-website
npm run validate && npm run build          # 校验 + 构建
bash deploy-speak.sh --dry-run             # 部署前必查删除项
bash deploy-speak.sh                       # 需用户明确授权

node scripts/burn_ket_audio.mjs <场景id>...  # 烧 rosie+chris(按 audio map,幂等)
node scripts/burn_daily_audio.mjs <burn.json> # 烧 rosie(按清单)
node scripts/review_fce_deepseek.mjs <content.json>  # v4pro 双卡
node scripts/gen_gpt_review_pack.mjs       # 生成 GPT 终审包

# iOS 装机(设备 id 固定)
cd ../Speak-ios && rm -rf build
xcodebuild -project Speak.xcodeproj -scheme Speak -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build build
xcrun devicectl device install app --device 388E2104-A8B0-5562-943D-78CE281B7F36 \
  build/Build/Products/Debug-iphoneos/Speak.app
```

---

## 七、下次开场提示(可直接拷贝)

```
继续 Speak(原版娃口语)。先读 Speak-website/docs/HANDOFF-2026-07-14-KET-FCE内容扩充.md。

当前:iOS 原生主力,73 场景 1137 句,web 已部署,iOS 本地装机验收中(改动未提交 git)。
三重质检流程已跑通:Claude 生成 → DeepSeek v4pro 双卡 → GPT 终审。

下一步做:剩 12 个 KET 话题补 Part 2(按官方题型:两名考生看5幅图各自谈喜好+原因、
回应对方、不要求达成一致;不是"共同决定"的角色扮演)。走完整三重质检。

⚠️ 铁律:审核 prompt 绝不能把标准喂给模型,要用三步法(先让它自己交代官方题型
→ 再对照判定 → 最后审语言),否则就是拿自己的错误当尺子量。

我的英语能力有限,内容质量靠多 AI 互审把关。iOS 改动请装到真机(设备已配对)让我验收,
web 部署要我明确授权。
```
