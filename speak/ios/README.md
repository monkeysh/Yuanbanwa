# 原版娃口语 (Speak)

SwiftUI iOS app — 场景跟读口语练习. Sibling of the `Speak-website` HTML prototype,
pulls the same `scenes.json` content.

**Bundle ID:** `com.yuanbanwa.speak`
**Team ID:** `FQAVS46R89` (shared with Unlock·RE)
**Min iOS:** 17.0

## 打开 / 运行

```bash
cd Speak-ios
open Speak.xcodeproj
```

Xcode 里选一个 iOS 17 模拟器（iPhone 17 / 15），⌘+R 运行。

## 修改场景内容

编辑 `Speak/Resources/scenes.json` —— web 版和 iOS 版共用这份数据。
改完重新打包 iOS（⌘+R）或 redeploy web。

## 重新生成 Xcode 项目

当你在 `project.yml` 里改了 target/设置后：

```bash
/tmp/xcodegen/xcodegen/bin/xcodegen generate
```

或装到 /usr/local/bin：

```bash
cp /tmp/xcodegen/xcodegen/bin/xcodegen /usr/local/bin/
```

## 结构

```
Speak-ios/
├── project.yml                  ← xcodegen spec
├── Speak.xcodeproj              ← 生成，不手改
└── Speak/
    ├── SpeakApp.swift           ← 入口
    ├── Models/
    │   ├── Models.swift         ← SpeakScene / SceneSentence / ReviewItem
    │   ├── SceneRepository.swift ← 读 scenes.json
    │   └── AppStore.swift       ← 全局状态（tab、进度、复练队列）
    ├── Theme/
    │   ├── Palette.swift        ← Cream + Dusk 两套色板
    │   ├── ThemeManager.swift   ← 主题切换（含"跟随系统"）
    │   ├── Typography.swift     ← 字体
    │   └── Haptics.swift        ← 触感反馈
    ├── Views/
    │   ├── RootView.swift       ← TabView + 路由
    │   ├── Components/          ← Chip / Buttons / SceneGlyph / PlantIcon
    │   └── Screens/             ← 6 个主页面
    ├── Assets.xcassets          ← App 图标、颜色
    └── Resources/
        └── scenes.json          ← 8 个场景内容（和 web 共用）
```

## 已完成（P0）

- ✅ SwiftUI 项目骨架可编译、可运行
- ✅ 双主题（奶油白天 / 暮色夜晚 / 跟随系统）
- ✅ 4 个 tab：首页 / 场景馆 / 复练 / 我的
- ✅ 主流程导航：首页 → 场景详情 → 跟读 → 结果
- ✅ 8 个场景 63 句内容从 JSON 读入
- ✅ 复练队列（带 badge）
- ✅ 数据持久化（UserDefaults，迁到 SwiftData 是 P2）
- ✅ 触感反馈接到所有关键交互
- ⏳ 录音流程是 2 秒 setTimeout 模拟 —— P1 接 AVFoundation + SFSpeechRecognizer

## P1 计划（下一步）

1. 真实录音 + Apple Speech 本地识别
2. 词级相似度打分（Levenshtein + phonetic fuzzy）
3. 反馈卡片上真实波形对比

## P2 计划

1. App 图标精修 + 匹配 原版娃学词 的视觉家族
2. 发音评分引擎升级（SpeechAce / 讯飞）
3. Push 通知 + 每日提醒
4. TestFlight 首轮外测
