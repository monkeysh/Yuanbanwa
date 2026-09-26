# 原版娃口语 · Shadow

面向英语开口焦虑用户的场景跟读站。产品只做两块：日常对话跟读与剑桥考试对话（KET / PET / FCE），线上地址为 <https://speak.yuanbanwa.top>。

当前网页是无需账号的 20 分钟公开体验。昵称可选，仅保存在当前浏览器；语音反馈来自浏览器 Web Speech API，展示的是“词句完整度”，不是音素级发音评分。不支持语音识别时会明确显示本句未评分。

## 本地开发

```bash
npm ci
python3 -m http.server 8000
# 打开 http://127.0.0.1:8000
```

源码仍集中在 `index.html` 的内联 JSX 中，方便快速迭代。源码预览使用 CDN 版 React/Babel；生产环境必须执行构建，生成自托管、预编译并带内容哈希的 `dist/`：

```bash
npm run validate
npm run build
npm run preview
# 打开 http://127.0.0.1:8000
```

## 目录

- `index.html` — 主应用、页面、状态和浏览器端存储逻辑
- `scenes.json` — Web / iOS 共用的 60 个场景、724 条分档句子
- `audio/` — Rosie / Chris 音频
- `scripts/validate_site.mjs` — 内容、音频、关键回归与进度迁移校验
- `scripts/build.mjs` — 生产构建；输出到被忽略的 `dist/`
- `terms.html` / `privacy.html` / `support.html` — 用户协议、隐私说明与帮助支持页（App Store 支持 URL）
- `deploy-speak.sh` — 严格白名单构建和部署脚本
- `ops/speak-soe/` — 独立的 SOE 服务硬化方案；满足认证前置条件前不得上线
- `docs/HANDOFF-P0-P1-2026-07-11.md` — 本轮 P0 / P1 接力说明

## 部署

先预演并人工检查删除/新增清单：

```bash
bash deploy-speak.sh --dry-run
```

得到明确上线授权后才执行：

```bash
bash deploy-speak.sh
```

部署脚本会先运行生产构建，只同步 `dist/` 白名单，默认创建远端快照，再用 `rsync --delete` 镜像到 `speak.yuanbanwa.top`。本轮代码尚未部署生产。
