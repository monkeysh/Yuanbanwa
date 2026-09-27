# Speak v2.1 定稿 · read 的口语输出模块

> 状态:**v2.1 定稿(2026-06-20)**。迭代:v1 初稿 → v2(5 路交叉审)→ v2.1(GPT 终审 8.6/10 + 用户拍板)。可进阶段 -1 / 阶段 0。
> 配套:`方案交叉审-2026-06-20.md`(5 视角)、GPT 终审清单。原型:`prototype-v2.html`(整体 IA)、`prototype-chat.html`(陪练核心)。

> **一句话定稿**:Speak 第一版不是独立 AI 陪聊,而是 **read 的口语输出模块**——孩子读完一篇分级外刊后,用**半开放句卡轨道**和 Rosie 做 3-5 分钟低压对话,把读懂的内容说出来;系统记录开口过程,沉淀为**每周家长报告**。第一版只验证:A2/B1 愿不愿持续开口、家长愿不愿为读说一体升级、ASR 在半开放轨道中够不够用。

---

## 0. 定位(已拍板)
- **read 输入 / speak 输出**;**技术独立 · 商业依附 read · 内容联动**(2026-06-20 拍板:第一版作 read 增值/续费模块,不独立获客;验证通过再开独立入口)。
- **不绑中考应试**(拍板):纯素质 / 外刊精读输出定位,避开变窄、损高端感、教培合规风险。差异化靠"读说一体 + 家长可见成果"。
- ⚠️ 反例:做成"一个有 Rosie 头像的对话框"= 更贵更笨更窄的豆包,必死。优势全在豆包结构上给不了的(详见 §7)。

## 1. 诊断
v1 四错位:自造分级 / 假反馈 / 孤立场景与 read 割裂 / 无对话。结论:重做。

## 2. 决策记录(全拍板)
| 项 | 定 |
|---|---|
| 定位 | read 增值/续费模块(技术独立·商业依附·内容联动) |
| 核心 | 半开放情景对话,**MVP 收窄到「读后说」** |
| 分级 | 三层:read band 输入 / S-band 输出 / speaking profile 记录(不说"蓝思=口语分") |
| 反馈 | 整句轻反馈,不假装评发音、不给假分数 |
| 平台 | iOS 优先(原生资产已做完,接线 + 补网络层) |
| 起步 | A2+B1(⚠️ A2 读后说要轻) |
| 节奏 | 先验证(阶段-1)再开发 |
| 蓝思中台 | 远期,移出路线图(§8) |
| 中考 | 不绑 |
| 套餐 | read 会员 + Speak 月度对话额度(不永久无限) |

## 3. 分级三层(GPT 模型)
| 层 | 名称 | 用途 |
|---|---|---|
| 阅读输入难度 | read band(Lexile/CEFR) | 文章/主题输入难度 |
| 口语训练档 | **S-band** | 句卡/语速/支架/对话复杂度;默认 = read band − 1,真口语定级修正 |
| 口语表现记录 | **speaking profile** | 开口表现/流利度/听辨/复述/表达完成度 |
对外话术:"基于蓝思分级外刊的口语输出训练";内部:read band 输入 + S-band 输出。⚠️ 杜绝"阅读 B1 = 口语 B1"伪科学跳跃。

## 4. 产品形态

### 4.1 信息架构
主入口在 **read 文章末**(「把这篇说出来 / 和 Rosie 聊聊这篇」);speak 内:首启**真口语定级** → 今日/训练/我的。受众分层:孩子端轻爽、家长端独立报告。

### 4.2 核心闭环 = 读后说(MVP)
```
读完 read 文章 →「和 Rosie 聊聊这篇」→ 预学(3 关键词 + 3 句型)
→ 半开放对话 5 轮 → 末尾自由表达 → 口语小结 → 周报沉淀
```
- ⚠️ **A2 要轻**:读后复述 / 说几句(主题、我喜欢什么),**不让 A2 讨论观点**(那是 B1);否则门槛过高、违背降焦虑。
- B1:解释外刊主题 / 表达观点给理由 / 和 Rosie 讨论文章一个问题。
- 产出"我能用英语讲这篇文章了"的小报告。

### 4.3 半开放轨道(防点读机铁律)
每轮给 2-3 张句卡(可点可听)。⚠️ **句卡是支架不是答案按钮:默认必须开口说,不能纯点击过关**。
流程:Rosie 问 → 出句卡 → 可点看/听 → **必须录音说出**(ASR 匹配句卡或识别自由表达)→ 说不完整也可过,但**不能纯点击过关**。
任务清单隐式;A2 无 curveball/KPI;同场景变式复现(第二次换问法)对抗背诵;末尾留一个自由产出出口。

### 4.4 反馈(三类边界,不给假分数)
| 反馈 | 第一版 | 来源 |
|---|---|---|
| 内容是否回应问题 | ✅ 做 | LLM + 任务目标 |
| 语法/表达是否自然 | ✅ 做 | ASR 文本 + 句卡匹配 |
| 发音是否准 | ❌ 不强评分 | 录音自比 + minimal pairs 听辨 |
| 流利度 | 暂弱化 | 录音时长/停顿粗估 |
| 单词发音分 | ❌ 不作正式能力分 | ASR 词级仅辅助 |
⚠️ 禁"你的发音 92 分";用"Rosie 听懂了大部分""这句说清楚了""有一处可以更自然""再练一次这个句型"。整句反馈(非实时)、每次最多纠 1 处、关键错给一次"重说一次"(uptake)闭环。

### 4.5 学一遍预学(输入冗余)
8-12 句输入(目标 5 + 被动听 3-5);目标句跟读 2-3 遍 + 一次"听中文说英文"提取练习;curveball 应对句先在预学被动出现;"会听到"的 Rosie 台词先做听辨(补听力解码——中国学生开口的真正前置瓶颈)。

### 4.6 受众分层 + 家长报告 v1(固定 4 块)
孩子端:打开 < 15 秒开口、Rosie 反应要"活"(真开心接话非弹 toast)。
家长报告 v1 固定:① 本周开口成果(完成 X 次、说出 X 句)② 3 段最佳录音(可播可转发)③ 本周进步点("能用 because 给理由"…)④ 下周建议。⚠️ 第一版**不堆评分/曲线/雷达图**——家长要的是"听到孩子真开口了、比上周多说了、能转发给家人"。

## 5. 技术架构

### 5.1 双端
Speak-ios ~4650 行真原生,`SpeechRecorder`(文件式 ASR)+ `PronunciationScorer`(词级打分)**已做完并接入 UI**;⚠️ 但**无网络层 + mock 登录** → 阶段 0 先建客户端通信层。Web 配套。

### 5.2 ASR(整句轮次,非实时)
文件式 `SFSpeechURLRecognitionRequest`(已绕 iOS26 引擎 bug),录完 → 转写 → 反馈。半开放轨道核心指标 = **句卡匹配准确率**(说的是不是 3 张卡之一),非开放听写。

### 5.3 后端 `/api/speak` 必修地基
独立命名空间 + 配额(仿 IELTS/TOEFL 隔离)。复用现状勘误:`/api/speaking/chat` 无状态单轮、TTS 非流式、零配额、缺 enable_thinking。阶段 0 必修:
1. 补 `enable_thinking:false`(顶层)+ 收紧超时
2. 真实 `usage.total_tokens` 计量 + 口语配额(对话轮次 + TTS 字符)+ 耗尽降级(退预生成跟读)
3. iOS 客户端通信层(HTTP/JWT/Keychain/TTS 播放/重试)
4. 端到端延迟预算(目标 < 2.5s,否则回复做短 + "Rosie 在想…"占位)
5. **会话状态服务端化**:至少 `conversation_id / scene_id / turn_index / s_band / task_state / last_summary`(否则家长报告/完成度/复盘/成本审计都痛)
6. **TTS 缓存**:`key = voice+text+speed+emotion`,高频短句("Great job!""Try again.")命中缓存,降成本降延迟
7. **儿童安全边界**(进 systemPrompt + 红队测试):Rosie 不聊成人/暴力/政治极端/隐私诱导/线下见面/联系方式;不索要真实姓名/学校/住址/电话;敏感内容转回学习任务
- TTS:跟读/预学**预生成**(离线 MP3,零实时成本);仅对话回复实时(先整段合成 + 回复做短);Rosie CosyVoice 复刻,voice 真值源收敛 `config` 一处。

### 5.4 数据模型(sp_* 从第一天记 —— 过程资产 = 壁垒)
- `sp_profiles`(user_id, current_s_band, placement_status, placement_result_json, ts)
- `sp_scenes`(id, read_article_id?, s_band, cefr, theme, title, system_prompt, target_phrases_json, passive_input_json, minimal_pairs_json, status)
- `sp_sessions`(id, user_id, scene_id, s_band, started/completed_at, total_turns, spoken_turns, duration_s, completion_state, cost_tokens, cost_tts_chars)
- `sp_turns`(id, session_id, turn_index, rosie_text, user_asr_text, matched_card_id, audio_url, feedback_json, ts)
- `sp_parent_reports`(id, user_id, week_start, summary_json, best_audio_turn_ids, ts)

### 5.5 账号/会员
仿 read 手机号 + 验证码;`profiles.speak_activated`(已存在)只读判权益,第一版**不写主站 profiles**。

## 6. 路线图

### 阶段 -1 · 验证(不写产品代码,1-2 周,最高优先)
| 验证 | 硬指标 | 不通过 |
|---|---|---|
| 孩子持续开口 | D1 首体验完成 ≥70% · D3 完成 2 次 ≥40% · D7 完成 3 次有效开口 ≥30% · 单次有效开口 ≥8 句 · 单局完成 ≥60% | 重想产品逻辑 |
| 家长付费意愿 | read 用户:A. 加 19.9 预约 7 天体验 / B. 升级读说套餐月差价 30-50(**定金/支付**,非留资) | 意愿低 → 降级或停 |
| ASR 半开放可用 | 句卡匹配准确率 ≥90% · 关键词识别 ≥85% · 严重误判 ≤10%(开放自由句仅参考) | 重想轻反馈 |
> 用**现有 iOS app**(已能真录真评)+ read 入口做,几乎零开发。

### 阶段 0 · 地基
iOS 接线 + 网络层 / §5.3 必修地基 / speak 真口语定级 / scenes 蓝思化 + read 文章关联。**不做蓝思中台、不写主站 profiles。**

### 阶段 1 · 读后说 MVP(首里程碑)
read 文末入口 + 读后说闭环(预学 → 半开放对话 → 自由表达 → 小结)+ **A2 6 场景 / B1 3 场景**(从 read 高频主题切):
- A2:自我介绍 / 我的学校 / 我的爱好 / 健康生活 / 一次旅行 / 我喜欢的一篇文章
- B1:解释一个外刊主题 / 表达观点并给理由 / 和 Rosie 讨论文章里的一个问题
+ 家长报告 v1 + 句卡防点读机 + 儿童安全边界。
验收:孩子读后能轻松说几句被夸、家长收到开口报告、read 用户愿升级。

### 阶段 2 · 扩 + 变式 + 真定级打磨
场景扩容、变式复现、口语定级精修;(可选)留存好再评估真发音评测。

### 阶段 3 · 读说闭环深化
read 243 篇深度联动、双向导流。

## 7. 商业
- **定位**:read 增值/续费模块,拉高 read 客单价与续费率,不独立获客。
- **套餐**(read 会员 + Speak 月度对话额度;⚠️ 跟读/预学/句卡不限量,**实时 AI 对话设额度**):
  - 读说月卡:read 全库 + Speak 120 轮/月 + 周报
  - 读说季卡:read 全库 + Speak 180 轮/月 + 周报 +(未来)专项包
  - ⚠️ 可永久 read,但 **Speak 必须月度配额,不做"永久无限口语"**。
- **成果交付物**:家长开口周报(§4.6)= 把"过程"固化成可炫耀资产 = 真壁垒。
- **单位经济**(动工前必算):单次会话 token×Qwen + TTS 字符×CosyVoice = 单次成本;× 月活跃次数 = 每用户月成本 → 反推额度与定价。
- **vs 豆包**:不在"AI 聊得好"比(必输);赢在豆包结构上给不了的——消除"怎么练"决策负担(方便)、垂直精准分级/靶向(精准)、家长可见成果(付费理由)、有记忆的 Rosie 陪伴、read 内容联动。

## 8. 风险与待决
- 最大风险 = 没验证就开发 → 阶段-1 对冲。其余:ASR 中式发音准度 / 端到端延迟 / 句卡退化成点读机 / 儿童安全。
- **未来基础设施(不在当前路线)**:当 read/speak/vocab 至少两个需共享能力档案时,再启动独立蓝思/能力中台(归属主站 server,与 speak 解耦)。
- 待办:单位经济实算 / 阶段-1 真实样本招募 / iOS swift 通读盘点。

## 9. 关键文件索引
- read 分级/定级:`Lexile/src/data/graded.ts`、`Lexile/src/screens/PlacementTest.tsx`(⚠️ 在 `Lexile/`,是 15 题启发式、非精确分)、`Lexile/src/services/store.ts`
- 口语后端(勘误):`server/src/routes/speaking.ts`(单轮/TTS非流式/零配额/缺 enable_thinking)、`writing.ts:225`(enable_thinking 范本)、`config.ts`(voice 真值源)
- iOS 资产(已做完):`Speak-ios/Speak/Audio/SpeechRecorder.swift`、`PronunciationScorer.swift`;无网络层:`Speak-ios/Speak/Auth/AuthManager.swift`
- 权益字段已存在:`server/src/db/migrations/2026_04_24_speak_activated.sql`
- 审稿:`Speak-website/docs/方案交叉审-2026-06-20.md`
- 原型:`Speak-website/prototype-v2.html`、`prototype-chat.html`
