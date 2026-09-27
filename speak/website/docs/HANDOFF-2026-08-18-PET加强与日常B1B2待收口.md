# Speak 交接 · 2026-08-18

> 上一份:`docs/HANDOFF-2026-07-18-KET-Part2-模拟考官.md`(仍有效,本份是增量续接)
> 必读:`docs/日常场景内容生产检查清单-2026-08-16.md`(内容生产的踩坑总账,写任何新内容前先过一遍)

## 一句话现状

内容 **75 场景 / 1730 句已上线**(web),iOS 包已构建但**手机在洛杉矶未装机**。本次会话完成:日常 8 个生活刚需场景补深(已上线)、日常 B1/B2 两批共 **256 句文案已定稿但未 splice、未烧音频**(用户明确要求音频先 HOLD)。**下一步主任务:PET 加强。**

---

## 一、下个会话的主任务:PET 加强

### 现状(三个考试对比)

| 考试 | 话题数 | 句数 | 档位 |
|---|---:|---:|---|
| KET | **18** | 327 | Part 1 对话 / Part 2 讨论 |
| PET | **12** | 305 | Part 1 对话 / Part 2 独白 / Part 3 讨论 |
| FCE | 12 | 324 | Part 1 对话 / Part 2 独白 / Part 3 讨论 |

PET 四个 Part 已全覆盖(Part 4 由模拟考官承担,后端已部署双阶段弧线)。官方题型断言见 `docs/PET-官方题型断言-2026-07-31.md`——**这是所有 PET 内容的对照尺,动手前先读**。

### 建议的加强方向(按 ROI 排序,请用户拍板)

**① 话题从 12 扩到 18(对标 KET)** — 缺口最明显
KET 有而 PET 没有的 9 个话题:`animals / festivals / friends / holidays / home / jobs / personal / sports / transport`。
选 6 个补齐即可(建议 friends / home / sports / transport / holidays / jobs —— 更贴 B1 学生生活;animals 偏 A2,festivals 与 holidays 重叠)。
每个新话题要 Part1(8) + Part2 独白(7) + Part3 讨论(10-12) ≈ 26 句,6 个约 **156 句**。
⚠️ 现成素材:`docs/新增PET话题-GPT终审pack.md` 里有 v4pro 生成的 6 个话题草稿(health/weather/entertainment/technology/work/family),但**这 6 个已经上线了**,不是新的——别搞错。新话题要重写。

**② Part 2 独白偏短** — 官方约 1 分钟 ≈ 120-135 词
现在每组 6-7 句、约 75-100 词(Codex 体检报告 `_content-drafts/PET-Part2独白-体检报告-2026-08-01.md` 已量过)。
上次已给偏短的 5 组各补 1 句,但仍在下沿。可考虑统一补到 8-9 句。

**③ Part 3 内容量不足** — 官方 2 分钟讨论 + 1 分钟决策
现在 10-12 句。真实两阶段需要更多轮往来。若要做「完整计时模拟」需扩到 16-18 句;若定位「压缩跟读示范」则维持现状即可(Codex 终审已明确这是可接受的定位,只是不能标成"完整模考")。

**④ Part 2 缺搭档 30 秒回应** — 官方 Part 2 的完整结构是「A 独白 1 分钟 → B 回答一个 30 秒短问题 → 交换」。我们只做了独白部分。这是产品形态决策,需用户拍板要不要做。

**⑤ 考官 Part 4 只做了冒烟测试** — 后端已上线(前 4 题 Part1 → 后 3 题 Part4 观点),冒烟命中过一次。建议真机多跑几轮验收话题贴合度与题量。

### PET 内容生产的既有流程(照搬即可)
```
Claude 生成 → v4pro 双卡(地道/语法) → Codex 三步法终审(题型/官方 handbook)
→ 采纳 → 二轮复核至收敛 → splice → 烧音频 → validate → 装机/部署
```
参考已跑通的脚本:`_content-drafts/pet-part3-batch.json` 的生产链、`scripts/burn_ket_audio.mjs`(幂等)。

---

## 二、在途未完成工作(不要丢)

### 日常 B1 / B2 两批文案已定稿,待落地

| 批次 | 内容 | 句数 | 文件 |
|---|---|---:|---|
| **B1** | emergency-call 补 3 档 + **新场景** car-breakin(车被砸·车内失窃)+ **新场景** insurance-claim(保险理赔) | 88 | `_content-drafts/daily-batchB1.json` |
| **B2** | starbucks / hotel-checkout / baggage / gate / customs / parent-meeting / sick-leave 各补 3 档 | 168 | `_content-drafts/daily-batchB2.json` |

**落地步骤**(音频等用户点头):
1. `python3 <scratchpad>/splice_batchB1.py`(已写好,含新场景创建、分类聚拢、遗留 sentences 字段兼容)
2. B2 的 splice 可复用 `splice_daily_deepen.py`(改数据源即可)
3. 预期:75 → **77 场景**,1730 → **1986 句**,烧音频约 700 个(rosie+chris 双声)
4. 然后 `npm run validate` → rsync iOS → 构建装机 → `bash deploy-speak.sh`

**两个审核结果没等到就交接了,下次先查**:
- B1 的 Codex 复核(查"修复时有没有引入新矛盾")
- B2 的 **CBP 合规专审**(过海关那档说错有法律后果,必须过这一轮才能上线)
产出路径分别是 `/tmp/b1_review2.md`、`/tmp/cbp_review.md`(若已被清理就重跑,审核包都在 `_content-drafts/GPT-*-审核包-*.md`)

### 其他欠账
- **iOS 未装机**:包已构建验证(bundle==源),手机 `388E2104-A8B0-5562-943D-78CE281B7F36` 在洛杉矶未连接
- **S3 发音体检**(学习数据第三步)未做:音素标签已实测确认是**小写 ARPABET 无重音数字**(`dh/eh/ah/iy...`,39 音素 CMU 集),映射表照这个做。S1 数据层/S2 成长页/S5 考官记录已完成
- **防诈骗话术**该放 phone-call 的「接听」档(现在的 beginner 档,按铁律没动),下次碰那个档时补
- 顶层 `sentenceCount` 口径已全站统一为 sum across tiers(2026-08-16 修过 18 处)

---

## 三、本次会话的重要教训(写进检查清单了,这里只列最贵的)

1. **一档 = 一条连贯叙事线,不是知识点清单**。把某场景所有高频表达堆进 advanced 档,会产生硬矛盾(药已配好 vs 需事前授权 vs 缺货三种互斥状态同时成立)。
2. **台词表的句子顺序 = 学员的行为顺序**。疑似急腹症的场景里,"问费用"排在"要不要叫救护车"之前,等于把「先问价再考虑叫救护车」练成肌肉记忆。
3. **entry 档不能为了"不与 beginner 重复"而写成更难的边角料** —— 会造成梯度倒挂(学员得先学完第二档才能用第一档)。入门与初级核心动作重合是应该的,只要更短更简单。
4. **凭想象写美国流程必错**。本次踩到的:美国车险不赔车内私人物品(走 renter's/homeowner's)、911 与非紧急线与网上报案是三条渠道、DR number 与 incident number 不是一回事、加州没有法定零免赔玻璃险、酒店积分退房后才入账、航司原因误机走 involuntary rebooking 而不是 standby、中国"中杯"=美国 Tall。
5. **修复会引入新伤**。加了一句"我还没进屋"的安全提示,却没检查它和后面"我的电脑不见了"的关系——改动一句之后必须重读整档。
6. **审校分工**:v4pro 擅长重复检测与地道性;Codex 手里有官方 handbook 与美国真实流程,涉及法律/医疗/流程的必须过它;多视角对抗验证(Workflow)能抓出前两者都漏掉的系统性问题。

---

## 四、避坑清单(继承 + 新增)

| 坑 | 说明 |
|---|---|
| **音频要用户点头再烧** | 用户 2026-08-18 明确:文案先做到极致,音频最后一次性烧(改一次烧一次太浪费) |
| **web 部署要用户授权** | `bash deploy-speak.sh --dry-run` 先看删除项(应只删旧 hash bundle) |
| **现有 beginner 档一字不动** | 补档只加 entry/intermediate/advanced,老用户进度与音频零影响 |
| **音频命名** | beginner 档是历史格式 `{sid}_NN.mp3`,其余档 `{sid}_{level}_NN.mp3`;daily 每句烧 rosie+chris 双声(供「示范口音」切换,不是对话) |
| **句 ID 不可变** | `{sid}-{level}-{n}` + `legacyIds`;插入/排序不得复用改写既有 ID |
| **scenes.json 往返** | `json.dumps(indent=2)+'\n'` 与原文件字节一致;web 与 iOS 两份必须 md5 相同 |
| **Codex 会掉线** | `codex exec` 常报 stream disconnected,重发即可;DeepSeek reasoner 内容多时会把 token 耗在推理上返回空,要分批 |
| **session 额度** | Workflow 的 subagent 会撞额度;Codex(ChatGPT 额度)与 DeepSeek(API 额度)不受影响,可绕开 |
| **中英混入** | 生成中文时会混进英文单词(踩过 `today` / `operating` / 俄语 `это`),上线前跑正则自检 |
| **xcodegen** | 加文件后 `rm -rf build` 全量重建 |
| **git 隔离** | `git add Speak-website/`,不能 `-A`(会带 sibling);中文名文件被 git 转义成 `\347...` 是正常的,`grep '^Speak-'` 会误判为"非本目录"——假警 |

---

## 五、下次开场提示(可直接拷贝)

```
继续 Speak(原版娃口语)。先读 Speak-website/docs/HANDOFF-2026-08-18-PET加强与日常B1B2待收口.md,
再读 docs/日常场景内容生产检查清单-2026-08-16.md。

主任务:PET 加强。现状 PET 12 话题(KET 有 18),四个 Part 已全覆盖。
建议方向按 ROI:①话题 12→18(补 friends/home/sports/transport/holidays/jobs)
②Part2 独白偏短(现 6-7 句约 75-100 词,官方约 1 分钟需 120-135 词)
③Part3 内容量(现 10-12 句,官方 2 分钟讨论+1 分钟决策)
④Part2 缺搭档 30 秒回应(产品形态决策,要我拍板)
⑤考官 Part4 只冒烟过,要真机多验几轮
先给我方案再动手。

⚠️在途别丢:日常 B1(88句:911/砸车/保险,含两个新场景)与 B2(168句:旅游5+学校2)
文案已定稿在 _content-drafts/daily-batchB1.json 与 daily-batchB2.json,
未 splice、未烧音频(我要求音频最后一次性烧)。两个审核结果要先查:
B1 的 Codex 复核、B2 的 CBP 合规专审(过海关说错有法律后果,必须过)。

铁律:①内容生产先读检查清单,别凭想象写美国流程 ②一档=一条连贯叙事线
③台词表的句子顺序就是学员的行为顺序(安全相关) ④现有 beginner 档一字不动
⑤音频等我点头再烧,web 部署要我授权 ⑥我英语能力有限,质量靠多AI互审
(v4pro 抓重复与地道,Codex 有官方 handbook 与美国流程,涉法律/医疗/官方题型必须过它)
```
