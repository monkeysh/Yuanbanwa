# Speak 交接 · 2026-07-18

> 上一份:`docs/HANDOFF-2026-07-14-KET-FCE内容扩充.md`(仍有效,本份是增量续接)

## 一句话现状

Speak = **iOS 原生主力**(网页降级引流/试用)。内容 **73 场景 1197 句**(962 Rosie + 235 Chris 真人音频),web 已部署 <https://speak.yuanbanwa.top>;**iOS 侧全部改动本地装机验收中、未提交 git**。三重质检流程(Claude → v4pro 双卡 → GPT 终审)已成型并两次救回题型级事故。设备 id `388E2104-A8B0-5562-943D-78CE281B7F36`。

---

## 一、这几天(07-14→07-18)新增

### KET Part 2(核心工作)
KET 18 话题原本**全是单档 8 句**(只有 Part1 问答,最薄)。补 Part2 = **Part1对话8 + Part2讨论10 = 18句/话题**。
- **已补 12/18 话题**:第一批(hobbies/food/holidays/sports/festivals/family)+ 第二批(shopping/school/weather/health/animals/jobs)
- 全部走**三重质检 + GPT 引 handbook**,详见下方"官方题型"
- 音频 rosie+chris 已烧,校验绿

### 模拟考官三连 bug 修复(07-18,用户截图报的)
后端 `speak-soe/server.js`(拉取到 scratchpad 改再 scp 回):
1. **6/N 提前结束→卡死**:①`examMaxQ` 降 **KET6/PET7/FCE8**(真实 Part1 就5-6题,消除 AI 和 maxQ 打架);**⚠️前端 `ExamScreen.maxQ` 也硬编码,必须同步**(改成 6/7/8)。②兜底:`asked>=maxQ` 强制结束 + `!question && !isEnd` 顺势结束(AI 不给问题=想收);**绝不能用 `asked<maxQ 强制 isEnd=false`**(会导致既不结束也没问题=卡死)。
2. **结束语说2遍**:AI 把结束语同时塞 reaction+question,前端两处各 append 一次 → **isEnd 时后端强制 `question=''`**。
3. **中文 questionZh 从第3轮起空**:AI 多轮偷懒 → **兜底翻译**(question 非空但 questionZh 空,补一次 deepseek 译 `{"zh":...}`)。⚠️**踩坑**:曾试把 history 回放的 assistant 改纯文本"根治",结果 `response_format json_object` 模式下历史混纯文本 → DeepSeek 输出截断整个崩。**json_object 模式所有 assistant 历史必须合法 JSON**。

### streak 修复(07-13,用户报"统计天数每天0")
`AppStore.recordPractice` 从不更新 `streakDays`,加 `lastPracticeDay`+`updateStreak()`。⚠️需真机跨天验证。

### 模拟考官维度轮转重构(07-14)
VARIANTS 从"具体话题"改「切入维度」(习惯/经历/喜好/观点/对比/变化/困难/建议)——维度×任何话题都成立,不跳题;prompt 明确 topic 是「领域」非「任务」(功能型场景如 Ordering at a café 要问爱吃什么,不考"点餐难不难");`GENERIC_OPENER` 正则打回"What's your name"重问。

### 考官中文提示(07-18)
模拟考官每个问题下方加中文小字(`questionZh`)——用户英语不足,这是他的验收抓手,也是 KET/PET 学生刚需。ExamScreen.Bubble 加 `zh` 字段。

---

## 二、官方 A2 Key Speaking Part 2 正解(GPT 两轮引 Cambridge handbook)

**这是本项目最贵的教训——我凭臆想做错过一次题型,v4pro/Qwen 都没看出,只有 GPT 查了官方。**

- **Phase 1**:两名考生看**5幅同主题图**,先自由讨论1-2分钟,各自谈**喜欢/不喜欢+原因**,回应对方;**绝不要求达成一致**(喜好不同正常)。
- 考官随后介入提 `Do you think...?`,分别问两人**最喜欢哪个**。
- **Phase 2**:考官收回图,同主题延伸,每人约2问,**考官主导**。
- 官方明确**建议避免背诵整段套话**;"尽量谈到所有图片"是表现目标,**不是机械逐图报到**。
- **不是**决策/共同选一个,**不是**角色扮演(约时间/组订单=错)。

**我们的映射**:Part2 档 = Phase 1 考生示范;考官介入+Phase2 = **AI 模拟考官**承担。label 叫「Part 2 讨论」不叫"完整 Part2",不误导。

### GPT 反复挑的通病(做新内容要避开)
- **套路化**:12组开头别全是 "Do you like these X? I really like Y";Me too→What about→Really 别每组同骨架;结尾别都 "X is my favourite. What about you?"(考官本来会问最爱)。
- **5图覆盖**:自然带到5幅图,不能漏(weather 曾漏 cloudy);但也别死板凑。
- **地道/逻辑**:GPT 强项(sleep early→go to bed early / beautiful for parties 搭配 / 偏好前后冲突 / a coat 指代)——这些 v4pro 和我都易放过。

---

## 三、三重质检工具与流程

```
Claude 生成 → DeepSeek v4pro 双卡(地道/语法) → GPT 终审(难度+官方题型)
```

- v4pro 双卡:`scripts/review_fce_deepseek.mjs`(deepseek-reasoner)/临时 `/tmp/review_ket_*.mjs`
- GPT 终审包:`scripts/gen_gpt_review_pack.mjs` 生成 md,用户拿去 Codex/ChatGPT 跑,贴回
- ⭐ **铁律:审核 prompt 绝不能喂"标准"给模型**,用三步法(先让模型自己交代官方题型→对照判定→审语言),否则拿自己的错当尺子量(v4pro 曾判错题型内容"完全符合")。
- ⭐ **多AI互审价值=知识边界不同**:v4pro/Qwen 擅长语言地道,GPT 手里有官方 handbook。凡"全真模拟考试"内容**必须过 GPT**。用户英语不足,这套互审是唯一质量防线。

---

## 四、待办(建议优先级)

1. **最后 6 个 KET 话题补 Part2** → KET 18/18 全有。待补:`ket-personal`(认识新朋友)/`ket-travel`(问路去车站→转"城里的地方")/`ket-daily`(日常作息)/`ket-home`(温馨的家→房间)/`ket-friends`(好朋友→和朋友做的活动)/`ket-transport`(怎么去→交通方式)。**功能型(travel/transport)转对应话题领域**。走完整三重质检,避开上面的通病。
2. **KET/PET 话题扩充**(FCE 已 6→12,KET18/PET12 可再扩)
3. **考官换真人音频**(现系统 TTS,可预烧高频题库 Rosie/Chris)
4. **剩 16 单档日常场景**补4档(星巴克/过海关/药店/打电话等)
5. **web 部署**(iOS 已装机验收多轮,web 停在 07-14 的 73场景1137句,内容已领先未部署;要用户授权)
6. **iOS 改动提交 git**(本会话+前会话大量 iOS 改动未版本化)

---

## 五、避坑清单(继承+新增)

| 坑 | 说明 |
|---|---|
| **模拟考官 json_object** | examinerTurn 用 `response_format json_object`,**所有 assistant 历史必须合法 JSON**,塞纯文本会截断崩溃 |
| **maxQ 前后端同步** | 后端 `examMaxQ` 改了,前端 `ExamScreen.maxQ` 必须同改,否则顶部 x/N 显示错 |
| **LLM 软约束不听** | 禁夸奖/禁通用开场/maxQ/questionZh 都靠代码兜底,不赌自觉(sanitizeReaction/GENERIC_OPENER/isEnd强制/兜底翻译) |
| **Xcode 验证** | 真代码在 `Speak.app/Speak.debug.dylib`(5.5MB),主文件是91KB壳;中文串用 `grep -ac`/python bytes;注释不进二进制 |
| **xcodegen** | 加文件后 `rm -rf build` 全量重建,否则增量出旧包 |
| **git 隔离** | `git add Speak-website/`(不能 `-A`,会带 sibling);中文名 md 会被 git 转义成 `\347...`,`grep -vE '^Speak-website/'` 会误报,是假警 |
| **audio** | gitignore;iOS 同步改动句要 `rsync -a`(不加 `--ignore-existing`,否则覆盖不了旧音频);烧音频偶发 fail 1 个,重跑幂等补 |
| **scenes.json** | 标准2空格 JSON,`json.dumps(indent=2)+'\n'` 零差异;句子必须带 `legacyIds`;顶层 `sentences` 是遗留(tiers 优先,不渲染) |
| **烧音频超时** | `burn_ket_audio` 60+句会超 10min,`run_in_background` 跑,幂等续烧 |

---

## 六、常用命令

```bash
cd Speak-website
npm run validate && npm run build
bash deploy-speak.sh --dry-run          # 部署前必查删除项(应只删旧hash bundle)
bash deploy-speak.sh                     # 需用户授权

node scripts/burn_ket_audio.mjs <场景id>...   # 烧 rosie+chris(幂等)

# 模拟考官后端(在 scratchpad 改,scp 回):
scp yuanbanwa-server:/www/wwwroot/speak-soe/server.js /tmp/soe.js
# 改完: scp /tmp/soe.js yuanbanwa-server:/www/wwwroot/speak-soe/server.js
ssh yuanbanwa-server "node -c /www/wwwroot/speak-soe/server.js && pm2 restart speak-soe"

# iOS 装机:
cd ../Speak-ios && rm -rf build
xcodebuild -project Speak.xcodeproj -scheme Speak -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build build
xcrun devicectl device install app --device 388E2104-A8B0-5562-943D-78CE281B7F36 \
  build/Build/Products/Debug-iphoneos/Speak.app
```

---

## 七、下次开场提示(可直接拷贝)

```
继续 Speak(原版娃口语)。先读 Speak-website/docs/HANDOFF-2026-07-18-KET-Part2-模拟考官.md。

现状:iOS 原生主力,73场景1197句,web 停在07-14(73场景1137句,内容已领先未部署),
iOS 本地装机验收中(改动未提交git)。三重质检成型:Claude→v4pro双卡→GPT终审。

下一步:最后6个KET话题补Part2(personal/travel/daily/home/friends/transport),
KET就18/18全有。按官方A2 Key Part2:两名考生看5幅图各自谈喜好+原因、回应对方、
不要求达成一致;功能型场景(travel问路/transport怎么去)转成对应话题领域(城里的地方/
交通方式)。走完整三重质检,避开GPT反复挑的通病(套路化开头/漏图/favourite套路收尾)。

⚠️铁律:①审核prompt绝不喂标准,用三步法(先让模型自交代官方题型→对照→审语言)。
②模拟考官后端 json_object 模式下所有assistant历史必须合法JSON。③maxQ前后端同步。
④LLM软约束靠代码兜底不赌自觉。

我英语能力有限,内容质量靠多AI互审。iOS改动装真机(设备已配对)让我验收,web部署要我授权。
```
