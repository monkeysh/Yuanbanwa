import SwiftUI

struct SceneDetailScreen: View {
    let scene: SpeakScene
    @Binding var path: NavigationPath
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    // Which tier the user is previewing / about to practice. Single-tier
    // scenes lock this to their only tier; multi-tier scenes let the
    // user pick via the segmented control under the hero.
    @State private var selectedTierLevel: String = "beginner"
    @State private var showRolePicker = false   // 对话对练:选你演哪个角色

    private let previewLimit = 5

    private var selectedTier: SpeakSceneTier {
        scene.tier(level: selectedTierLevel) ?? scene.defaultTier
    }

    // 模拟考官只给剑桥 KET/PET/FCE 场景(自由问答=备考);日常场景不需要,只跟读。
    private var isCambridge: Bool { scene.track == "cambridge" }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                if scene.tiers.count > 1 {
                    tierPicker
                }
                metaRow
                if scene.isCambridge {
                    if let tip = scene.examTip, !tip.isEmpty {
                        section(title: "考点提示") {
                            VStack(alignment: .leading, spacing: 12) {
                                if let part = scene.examPart, !part.isEmpty {
                                    Text("🎯 \(part)")
                                        .font(AppFont.zh(size: 12, weight: .bold))
                                        .foregroundStyle(p.cam)
                                        .padding(.horizontal, 12).padding(.vertical, 4)
                                        .background(Capsule().fill(p.camSoft))
                                }
                                Text(.init(tip))   // 渲染 **加粗** markdown + 换行
                                    .font(AppFont.zh(size: 14)).foregroundStyle(p.ink).lineSpacing(5)
                                    .tint(p.cam)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(cardBg)
                        }
                    }
                    if let templates = scene.templates, !templates.isEmpty {
                        section(title: "答题锦囊 · 万能句型") {
                            VStack(spacing: 0) {
                                ForEach(Array(templates.enumerated()), id: \.offset) { idx, t in
                                    templateRow(t, isLast: idx == templates.count - 1)
                                }
                            }
                            .background(cardBg)
                        }
                    }
                } else {
                    section(title: "使用场景") {
                        Text(scene.description)
                            .font(AppFont.zh(size: 14))
                            .foregroundStyle(p.ink)
                            .lineSpacing(5)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(cardBg)
                    }
                }
                section(title: "本课将学会") {
                    VStack(spacing: 0) {
                        ForEach(Array(scene.learn.enumerated()), id: \.offset) { idx, item in
                            learnRow(item, isLast: idx == scene.learn.count - 1)
                        }
                    }
                    .background(cardBg)
                }
                sentencePreview
                Spacer(minLength: 20)
            }
            .padding(.bottom, 100)
        }
        .background(p.bg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { startCTA }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            // Snap selectedTierLevel to a tier that actually exists in
            // case we got here from a stale enum value.
            if scene.tier(level: selectedTierLevel) == nil {
                selectedTierLevel = scene.defaultTier.level
            }
        }
    }

    // MARK: - Tier picker

    private var tierPicker: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 8) {
            Text(scene.isCambridge ? "练习部分" : "难度档位")
                .font(AppFont.zh(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(p.inkMuted)
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(scene.tiers) { tier in
                        let on = tier.level == selectedTierLevel
                        Button {
                            Haptics.select()
                            selectedTierLevel = tier.level
                        } label: {
                            VStack(spacing: 2) {
                                Text(tier.label)
                                    .font(AppFont.zh(size: 13, weight: on ? .semibold : .medium))
                                Text("\(tier.sentenceCount) 句")
                                    .font(AppFont.zh(size: 10))
                                    .foregroundStyle(on
                                                     ? (p.isDark ? p.bg.opacity(0.7) : .white.opacity(0.75))
                                                     : p.inkMuted)
                            }
                            .foregroundStyle(on
                                             ? (p.isDark ? p.bg : .white)
                                             : p.inkSoft)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(on ? p.ink : p.surface)
                                    .overlay(Capsule().stroke(on ? .clear : p.line, lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Sections

    private var hero: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                SceneGlyph(kind: scene.kind, size: 72)
                VStack(alignment: .leading, spacing: 8) {
                    if scene.isCambridge, let part = scene.examPart, !part.isEmpty {
                        Text("\(scene.exam ?? "") · \(part)")
                            .font(AppFont.zh(size: 11, weight: .bold))
                            .foregroundStyle(p.cam)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Capsule().fill(p.camSoft))
                    } else if scene.isFeatured {
                        Chip(text: "今日推荐", tone: .accent)
                    } else if scene.isNew {
                        Chip(text: "新", tone: .accent)
                    }
                    Text(scene.title)
                        .font(AppFont.zh(size: 24, weight: .semibold))
                        .foregroundStyle(p.ink)
                }
                Spacer()
            }
            Text(scene.subtitle)
                .font(AppFont.enSerif(size: 17))
                .italic()
                .foregroundStyle(p.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [scene.isCambridge ? p.camSoft : p.accentSoft,
                                    (scene.isCambridge ? p.camSoft : p.accentSoft).opacity(0)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private var metaRow: some View {
        let p = theme.palette
        let items: [(String, String)] = [
            ("时长", "\(scene.minutes) 分钟"),
            ("句子", "\(selectedTier.sentenceCount) 句"),
            ("难度", selectedTier.label),
        ]
        return HStack(spacing: 10) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 4) {
                    Text(item.0)
                        .font(AppFont.zh(size: 11))
                        .foregroundStyle(p.inkMuted)
                    Text(item.1)
                        .font(AppFont.zh(size: 15, weight: .semibold))
                        .foregroundStyle(p.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(cardBg.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.zh(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundStyle(theme.palette.inkSoft)
            content()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func templateRow(_ t: AnswerTemplate, isLast: Bool) -> some View {
        let p = theme.palette
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(t.en)
                    .font(AppFont.enSerif(size: 16))
                    .foregroundStyle(p.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(t.zh)
                    .font(AppFont.zh(size: 11))
                    .foregroundStyle(p.inkMuted)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Capsule().fill(p.surfaceAlt))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            if !isLast {
                Rectangle().fill(p.line).frame(height: 1).padding(.leading, 16)
            }
        }
    }

    private func learnRow(_ text: String, isLast: Bool) -> some View {
        let p = theme.palette
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(p.sageSoft).frame(width: 20, height: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(p.sage)
                }
                Text(text)
                    .font(AppFont.zh(size: 14))
                    .foregroundStyle(p.ink)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            if !isLast {
                Rectangle().fill(p.line).frame(height: 1).padding(.leading, 16)
            }
        }
    }

    private var sentencePreview: some View {
        let p = theme.palette
        let preview = Array(selectedTier.sentences.prefix(previewLimit))
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("核心句子 · 预览 \(preview.count) 句")
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(p.inkSoft)
                Spacer()
                Text("共 \(selectedTier.sentenceCount) 句")
                    .font(AppFont.zh(size: 11))
                    .foregroundStyle(p.inkMuted)
            }
            VStack(spacing: 0) {
                ForEach(Array(preview.enumerated()), id: \.offset) { idx, sentence in
                    sentenceRow(idx: idx, sentence: sentence, isLast: idx == preview.count - 1)
                }
            }
            .background(cardBg)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func sentenceRow(idx: Int, sentence: SceneSentence, isLast: Bool) -> some View {
        let p = theme.palette
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle().fill(p.surfaceAlt)
                    Text("\(idx + 1)")
                        .font(AppFont.enSans(size: 11, weight: .semibold))
                        .foregroundStyle(p.inkSoft)
                }
                .frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(sentence.en)
                        .font(AppFont.enSerif(size: 17))
                        .foregroundStyle(p.ink)
                    Text(sentence.zh)
                        .font(AppFont.zh(size: 12.5))
                        .foregroundStyle(p.inkSoft)
                }
                Spacer()
                Button { Haptics.tap() } label: {
                    ZStack {
                        Circle().fill(p.surfaceAlt).frame(width: 28, height: 28)
                        Image(systemName: "play.fill").font(.system(size: 10))
                            .foregroundStyle(p.ink)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle().fill(p.line).frame(height: 1).padding(.leading, 48)
            }
        }
    }

    private var startCTA: some View {
        let p = theme.palette
        return VStack(spacing: 0) {
            LinearGradient(colors: [p.bg.opacity(0), p.bg],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
            VStack(spacing: 10) {
                // AI 模拟考官(自由问答)只在剑桥场景=备考;日常场景不给,只跟读。
                if isCambridge {
                    Button {
                        Haptics.tap()
                        showRolePicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.wave.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("AI 模拟考官 · 自由问答")
                        }
                        .font(AppFont.zh(size: 14, weight: .semibold))
                        .foregroundStyle(p.accentDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(p.accent.opacity(0.12)))
                        .overlay(Capsule().stroke(p.accent.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("选择你的考官", isPresented: $showRolePicker,
                                        titleVisibility: .visible) {
                        Button("女考官 Rosie") {
                            path.append(AppRoute.exam(exam: scene.exam ?? "KET",
                                                      topic: scene.subtitle,
                                                      topicZh: scene.title, examinerVoice: "rosie"))
                        }
                        Button("男考官 Chris") {
                            path.append(AppRoute.exam(exam: scene.exam ?? "KET",
                                                      topic: scene.subtitle,
                                                      topicZh: scene.title, examinerVoice: "chris"))
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("考官会像真实考试一样提问，你用英语自由作答，结束后给点评。")
                    }
                }
                PrimaryButton(action: {
                    path.append(AppRoute.practice(sceneId: scene.id,
                                                   tierLevel: selectedTier.level,
                                                   filteredIndexes: nil))
                }) {
                    Image(systemName: "mic.fill").font(.system(size: 16, weight: .semibold))
                    Text("开始跟读 · \(selectedTier.label)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
            .background(p.bg)
        }
    }

    private var cardBg: some View {
        let p = theme.palette
        return RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.surface)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(p.line, lineWidth: 1))
    }
}
