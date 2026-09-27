# CLAUDE.md

This file tells Claude Code how to continue work in `Speak-website/` safely.

## Product and isolation

`Speak-website/`（原版娃口语 / Shadow / 黛小美）是一个低门槛场景跟读 Web App，线上地址为 <https://speak.yuanbanwa.top>。它是 `Claude.English` monorepo 的独立 sibling，必须与最高优先级的 `unlock&re-website/`、共享 `server/` 以及 `yuanbanwa.top` 主站严格隔离。除非用户明确扩大范围，不要改这些 sibling 或共享服务。

当前产品只有两块，且共用同一套 `PracticeScreen` / `ResultScreen` / 复练流程：

1. `daily`：33 个日常对话场景（含 2026-09-26 合入的 car-breakin、insurance-claim）。
2. `cambridge`：42 个剑桥考试场景（KET 18 / PET 12 / FCE 12）。

“读说一体 / Rosie AI 陪练 / chatbot”方向已经搁置。`prototype-v2.html`、`prototype-chat.html` 和相关旧方案文档只供历史参考，不是当前产品。

## Current architecture

- React 18 单页应用，所有组件和状态仍集中在 `index.html` 的内联 JSX 中；没有 `src/`。
- `scenes.json` 是 Web 与 iOS 共用的内容源：75 个场景、240 个 tier、2014 条分档句子（2026-09-26 合入 B1/B2、2026-09-27 PET Part 2 加长后；其中 284 句音频待烧）。句子必须带不可变的显式 `id`；插入或排序时不得复用/改写既有 ID。
- 生产构建由 `scripts/build.mjs` 完成：esbuild 预编译 JSX，React / ReactDOM 自托管，应用文件名带内容哈希，`scenes.json` 请求带内容版本。部署时禁止直接上传源码 `index.html`。
- 源码 HTTP 预览仍使用 CDN React/Babel，只用于开发；`dist/` 中不得出现 `unpkg.com`、`text/babel` 或开发版 React。
- 进度和公开体验状态只保存在当前浏览器 localStorage；没有账号、短信验证码或后台身份。公开体验时长为 20 分钟，昵称可选。
- 语音评测三级：①`Pron`（腾讯云 SOE，经同域 `/api/soe`）＝真实音素级发音评分（总分/准确度/流利度/完整度＋逐词＋音素），前端自录 16k PCM 上传；②`Speech`（Web Speech API）＝仅“词句完整度”（目标词是否被识别）；③降级路径必须清楚显示“本句未评分”，不能生成假分数。SOE 网络/服务器错→本会话回落 ②；429 限流只提示重试不降级；麦克风被拒→③。发音 <60 的词以 `missedRefs` 进复练。
- `phase`（练习阶段）和 `playback`（示范音频状态）是独立状态；录音/分析期间不能播放示范音频，离开页面必须停止音频。

## Commands

```bash
npm ci
npm run validate
npm run build
npm run preview        # serves dist/ on port 8000
```

源码预览（用于快速开发）：

```bash
python3 -m http.server 8000
# http://127.0.0.1:8000
```

每次改 `index.html`、`scenes.json`、构建逻辑或进度迁移后，至少运行：

```bash
npm run validate
npm run build
git diff --check
```

涉及 UI 流程时还要在真实浏览器检查 390×844 和桌面视口、控制台错误、首页进入、两块场景馆、首次空复练、完成练习后的真实结果与复练留存。不要为了测试触发或保存真实用户语音。

## Production contract and deploy

```bash
bash deploy-speak.sh --dry-run   # read-only preview
bash deploy-speak.sh             # production mutation; requires explicit user authorization
```

`deploy-speak.sh` 每次都会重新构建，并仅允许以下生产载荷：

- `index.html`、`scenes.json`、`terms.html`、`privacy.html`、`support.html`、`build-manifest.json`
- 单个哈希化 app bundle 与本地 React / ReactDOM vendor bundle
- `assets/app-icon-180.png`
- `audio/rosie/*.mp3`、`audio/chris/*.mp3`

脚本默认先创建远端快照，再以 `rsync --delete` 镜像 `dist/`。正式部署前必须检查 dry-run 删除项；不要把 `.claude/`、测试页、源码、文档、环境变量或开发运行时发布到 Web 根目录。本项目没有 service worker，因此无需修改主站的 `unlock-vNN`。

## Data model and stable identity

`scenes.json` 顶层形状为 `{ version, categories, examTopics, scenes }`。场景使用完整字段；`transformScenesJSON()` 只在运行时映射为 UI 短字段。

- daily 场景默认 `track: daily`，tier 为 `entry / beginner / intermediate / advanced`。
- Cambridge 场景带 `track: cambridge` 与 `exam: KET | PET | FCE`，通常只有一个考试 tier。
- sentence 至少包含 `{ id, en, zh, words, weak, audio }`，可选 `voice`。
- `words` 是展示 token；`weak` 是作者预置的易错词索引，不是识别结果。
- `audio` 保存相对路径；`voice: chris` 用于男声 turn，其余优先 Rosie。
- 新内容必须先分析现有结构，再分配不变且同场景/tier 唯一的 ID，并同步校验、音频和 iOS 内容。

进度 key 为 `ybw.speak.progress.v1`，内部有 schema version。任何迁移必须幂等且只执行一次；不能在每次读取时把新加入的句子自动判为已完成。旧 `{sentIdx}` 和旧位置型句子引用必须迁移后再丢弃。

## Audio and content pipeline

音频目录约 46 MB：Rosie 724 个文件、Chris 127 个文件；当前内容实际首选 597 条 Rosie + 127 条 Chris。`playSentenceAudio()` 必须在 `Audio.play()` 拒绝或媒体错误时让 UI 恢复，不能永久停在“播放中”。

Cambridge 内容生产工具在 `scripts/`，中间稿在 `_content-drafts/`。典型流程是内容生成/复审 → 人工终审 → splice 到 `scenes.json` → 生成 Rosie/Chris 音频 → `ensure_rosie_keys.mjs` → 全站校验。API key 来自 sibling 的本地 `.env`，绝不能写进仓库或静态网页。

## SOE service: blocked from production

`ops/speak-soe/` 是对现有 `/api/soe` 的安全硬化包，包含 HMAC 短时签名、防重放、双重限流、并发限制、输入校验、严格 CORS、超时、非 root PM2 与 nginx 配置。

静态 SPA 不能安全持有 HMAC secret。只有在真实认证后端或可信签名网关就绪、客户端改为签名请求后才能部署这套 HMAC 硬化版；否则现有未签名请求会全部返回 401。部署硬化版时必须同时维护 root 与 `speak-soe` 用户的 PM2 dump，避免重启复活旧 root 进程。

**当前线上状态（2026-07-12，用户拍板）**：`/api/soe` 以「开放端点＋nginx 限流」上线（用户接受有限盗刷风险换真发音分）：`limit_req` 每 IP 20r/m burst=8、并发 2、body 1400k、子路径 404；zone 定义注入在 `speak.yuanbanwa.top.conf` 顶部（http 上下文），location 在 `/www/wwwroot/speak-soe/nginx.location.conf`。前端 `Pron` 模块已正式接入该端点。升级到 HMAC 硬化版仍以认证后端为前提。

## Current handoff

先读 `docs/HANDOFF-P0-P1-2026-07-11.md`。P0 已在本地修复，P1 已启动；生产尚未部署。继续工作时以代码和验证脚本为准，不要恢复旧的假分、种子复练、伪手机号/验证码或浏览器运行时 Babel 生产方案。

## Conventions

- UI 文案使用简体中文；组件和变量使用英文。
- 回复用户必须使用简体中文。
- 修改数据文件前先分析结构；不要机械覆盖 `scenes.json` 的无关格式或顺序。
- 只处理当前产品范围，保留工作区中与本任务无关的用户改动。
