Yuanbanwa.top 英语学习站点
=========

## 目录

- `speak/` — 原版娃口语（Speak）项目
  - `speak/website/` — Web 端（React 18 单页应用，esbuild 构建），说明见 `speak/website/README.md`
  - `speak/website/ops/speak-soe/` — 腾讯云 SOE 代理服务硬化版
  - `speak/ios/` — iOS 端（SwiftUI），说明见 `speak/ios/README.md`

## 在 Claude Code 云端会话中使用

仓库根目录的 `.claude/settings.json` 注册了 SessionStart 钩子（`.claude/hooks/session-start.sh`）。云端会话启动时会自动安装 `speak/website` 和 `speak/website/ops/speak-soe` 的 npm 依赖，之后即可直接运行：

```bash
cd speak/website && npm run validate && npm run build
cd speak/website/ops/speak-soe && npm test
```

音频文件（`speak/website/audio/`）不在版本库中。云端会话启动时若该目录不存在，钩子会自动设置 `SPEAK_ALLOW_MISSING_AUDIO=1`，让 validate / build 跳过音频存在性检查；需要真实音频时，把本地 `Speak-website/audio/` 目录同步到 `speak/website/audio/` 即可，此时检查恢复严格模式。
