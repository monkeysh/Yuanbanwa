# CLAUDE.md

Yuanbanwa.top 英语学习站点仓库。当前包含「原版娃口语 / Speak」项目，位于 `speak/`：

- `speak/website/` — 原版娃口语 Web 端（React 18 单页应用，esbuild 生产构建）。**先读 `speak/website/CLAUDE.md`**，它定义了产品范围、数据模型、构建与部署约束。
- `speak/website/ops/speak-soe/` — 腾讯云 SOE 代理服务硬化版（Node 18+，`npm test`）。
- `speak/ios/` — SwiftUI iOS 版（Xcode / xcodegen）。Linux 云端会话里没有 Xcode，只能阅读和修改代码，不能编译；改过 `project.yml` 或增删文件后，用户需在 Mac 上 `xcodegen generate` 再构建。iOS 的发音评测与 Web 端一样走 `/api/soe` 代理，App 内不含腾讯云密钥，也没有账号体系。

## 云端会话（Claude Code on the web）

`.claude/hooks/session-start.sh` 在会话启动时自动安装 `speak/website` 与 `speak/website/ops/speak-soe` 的 npm 依赖。

常用检查命令：

```bash
cd speak/website && npm run validate && npm run build && git diff --check
cd speak/website/ops/speak-soe && npm run check && npm test
```

音频目录 `speak/website/audio/`（ElevenLabs 生成，约 2800 个 mp3）按约定不进版本库。云端没有这些文件时，启动钩子会设置 `SPEAK_ALLOW_MISSING_AUDIO=1`，让 validate / build 把"音频文件不存在"降级为警告；本地与生产构建不设置该变量，仍然严格失败。云端构建出的 `dist/` 不含音频，不可用于部署。

密钥（ElevenLabs、腾讯云 SOE、DeepSeek 等）一律通过环境变量或被忽略的 `.env` 文件提供，绝不能写进仓库或静态网页。回复用户使用简体中文。
