# 原版娃口语 (Speak) · iOS

SwiftUI iOS App，场景跟读口语练习。与 `../website/`（Web 端）共用同一份 `scenes.json` 内容。

- **Bundle ID:** `com.yuanbanwa.speak`
- **Team ID:** `FQAVS46R89`（与 Unlock·RE 共用）
- **最低系统:** iOS 17.0
- **版本号:** 见 `project.yml` 的 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`

## 打开 / 运行

```bash
cd speak/ios
xcodegen generate      # project.yml 有改动时必须先重新生成工程（Speak.xcodeproj 是生成物，不手改）
open Speak.xcodeproj
```

Xcode 里选一个 iOS 17 模拟器，⌘+R 运行。发音评分和模拟考官需要网络，都走 `speak.yuanbanwa.top`。

xcodegen 安装：`brew install xcodegen`。加文件后 `rm -rf build` 全量重建。

## 当前功能（2026-09）

- 首页 / 场景馆 / 复练 / 我的 四个 tab；日常 31 个场景 + 剑桥 KET / PET / FCE 42 个场景，共 1730 句
- 跟读、对话对练、复练：真实录音（AVAudioRecorder，16 kHz 单声道 PCM WAV）+ Apple 语音识别转写
- 发音评分：录音经 `https://speak.yuanbanwa.top/api/soe` 代理送腾讯云 SOE，返回准确度 / 流利度 / 完整度 + 逐词 + 音素；评测失败时回落本机词匹配，不造假分
- 模拟考官：剑桥 Part 1 / Part 4 自由问答，走 `/api/soe/chat`（DeepSeek），发音按自由说模式评分
- 学习数据：每次练习落盘 `Documents/practice_log.v1.json`，成长页、发音趋势、考官记录
- 双主题（奶油 / 暮色 / 跟随系统）、示范口音切换、触感反馈
- 首次启动隐私政策同意页；「我的」页有用户协议、隐私政策、版本号入口
- **没有账号体系**：所有数据只在本机。曾经的手机号 + 验证码 mock 登录（含超管 001 / 218 免验证码）已于 2026-09-26 移除；真实账号上线前不要恢复，需要时可从 git 历史（提交 8848d5b 的 `Speak/Auth/`）取回 UI

## 结构

```
speak/ios/
├── project.yml                  ← xcodegen spec
├── Speak.xcodeproj              ← 生成，不手改
├── scripts/                     ← 音频与内容脚本（ElevenLabs，需 scripts/.env）
├── 录音脚本/                    ← 真人录音脚本 md/pdf
└── Speak/
    ├── SpeakApp.swift           ← 入口 + AppGate（隐私同意门）
    ├── PrivacyInfo.xcprivacy    ← Apple 隐私清单（UserDefaults / 文件时间戳 / 上传的音频与文本）
    ├── Privacy/PrivacyConsent.swift ← 首次启动同意页 + 协议/政策 URL 常量
    ├── Models/                  ← 场景与句子模型、进度状态、练习日志
    ├── Audio/
    │   ├── SpeechRecorder.swift ← 录音 + Apple 语音识别
    │   ├── SOE/SOEClient.swift  ← 发音评测代理客户端（/api/soe）
    │   ├── PronunciationScorer.swift ← 本机词匹配回落
    │   ├── SpeechSpeaker.swift  ← 考官 TTS
    │   └── AudioLibrary.swift   ← 示范音频
    ├── Theme/                   ← 色板、主题、字体、触感
    ├── Views/                   ← RootView + Screens + Components
    ├── Assets.xcassets          ← App 图标、颜色
    └── Resources/
        ├── scenes.json          ← 与 web 共用，必须字节一致
        └── audio/               ← 示范音频，不进版本库
```

## 修改场景内容

编辑 `Speak/Resources/scenes.json`。它和 `../website/scenes.json` 必须字节一致（md5 相同），改完两边都要更新，再跑 web 端的 `npm run validate`。

## 音频

`Speak/Resources/audio/` 不进版本库（约 84 MB）。用 `scripts/elevenlabs-generate.py` 或 web 端的 `burn_*_audio.mjs` 幂等重烧，然后 `xcodegen generate` 再构建。

## 上架前待办

- [ ] `xcodegen generate` 后在真机验收：发音评分（走代理）、模拟考官、首次启动隐私同意页、「我的」页协议链接
- [ ] 确认 Xcode 的 Copy Bundle Resources 里包含 `PrivacyInfo.xcprivacy`
- [ ] ICP 备案号（中国区上架必填）
- [ ] App Store 截图、描述、关键词、年龄分级、出口合规声明、支持页面
- [ ] TestFlight 外测
