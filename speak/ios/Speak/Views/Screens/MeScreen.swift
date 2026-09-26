import SwiftUI

struct MeScreen: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    // 学习数据 S2:成长数据从真实 session 日志聚合;进页时刷新一次
    @State private var growth = GrowthStats()

    private var completedCount: Int { store.completedSceneIds.count }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerRow
                streakCard
                WeekOverviewGrid(growth: growth, totalSentences: store.totalSentencesPracticed)
                TrendBars(growth: growth)
                heatmap
                SceneMapPanel()
                ExamLogPanel(growth: growth)
                voicePicker
                themePicker
                aboutRows
                Spacer(minLength: 40)
            }
            .padding(.bottom, 60)
        }
        .background(p.bg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { growth = PracticeLogStore.growthStats() }
    }

    private var headerRow: some View {
        let p = theme.palette
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [p.accent, p.sun],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                Text(avatarInitial)
                    .font(AppFont.enSans(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("学员")
                    .font(AppFont.zh(size: 20, weight: .semibold))
                    .foregroundStyle(p.ink)
                Text(subtitleLine)
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkSoft)
            }
            Spacer()
            Button { Haptics.tap() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17))
                    .foregroundStyle(p.inkSoft)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(p.surface))
                    .overlay(Circle().stroke(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var streakCard: some View {
        let p = theme.palette
        return HStack(spacing: 16) {
            PlantIcon(day: store.streakDays, size: 72)
            VStack(alignment: .leading, spacing: 2) {
                Text("连续打卡")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkSoft)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(store.streakDays)")
                        .font(AppFont.enSans(size: 44, weight: .medium))
                        .foregroundStyle(p.ink)
                    Text("天")
                        .font(AppFont.zh(size: 18, weight: .medium))
                        .foregroundStyle(p.inkSoft)
                }
                Text(store.streakDays < 14
                     ? "再 \(14 - store.streakDays) 天即满两周 🌿"
                     : "已满两周 🌿")
                    .font(AppFont.zh(size: 11, weight: .semibold))
                    .foregroundStyle(p.sage)
            }
            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(p.surface)
                GeometryReader { _ in
                    Circle()
                        .fill(RadialGradient(
                            colors: [p.sage.opacity(0.15), .clear],
                            center: .center, startRadius: 0, endRadius: 80
                        ))
                        .frame(width: 140, height: 140)
                        .offset(x: 160, y: -40)
                }
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(p.line, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private var heatmap: some View {
        let p = theme.palette
        // S2:真实近 28 天热力(此前是 sampleHeatmap 假数据,已铲)
        let values = growth.heat28.isEmpty ? Array(repeating: 0, count: 28) : growth.heat28
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("近 4 周")
                    .font(AppFont.zh(size: 14, weight: .semibold))
                    .foregroundStyle(p.ink)
                Spacer()
                HStack(spacing: 3) {
                    Text("少").font(AppFont.zh(size: 10)).foregroundStyle(p.inkMuted)
                    ForEach(0..<4) { v in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(heatColor(v, p: p))
                            .frame(width: 10, height: 10)
                    }
                    Text("多").font(AppFont.zh(size: 10)).foregroundStyle(p.inkMuted)
                }
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(["一","二","三","四","五","六","日"], id: \.self) { d in
                    Text(d)
                        .font(AppFont.zh(size: 10))
                        .foregroundStyle(p.inkMuted)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(heatColor(v, p: p))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            i == values.count - 1
                            ? RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(p.accent, lineWidth: 2)
                            : nil
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    private var themePicker: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            Text("外观")
                .font(AppFont.zh(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundStyle(p.inkSoft)
            HStack(spacing: 8) {
                themeButton(mode: .cream, label: "☀ 白天 · 奶油")
                themeButton(mode: .dusk,  label: "☾ 夜晚 · 暮色")
                themeButton(mode: .system, label: "跟随系统")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var voicePicker: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("示范口音")
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(p.inkSoft)
                Spacer()
                Text(statusLabel)
                    .font(AppFont.zh(size: 11))
                    .foregroundStyle(p.inkMuted)
            }
            // 产品声线:女 Rosie / 男 Chris(一行两个)。
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                 GridItem(.flexible(), spacing: 8)], spacing: 8) {
                voiceButton(.rosie)   // 女声
                voiceButton(.chris)   // 男声
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func voiceButton(_ v: VoicePreference) -> some View {
        let p = theme.palette
        let on = store.voice == v
        return Button {
            Haptics.select()
            store.voice = v
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Text(v.accentBadge).font(.system(size: 11))
                    Text(v.shortName)
                        .font(AppFont.zh(size: 13, weight: on ? .semibold : .medium))
                }
                Text(v.genderBadge)
                    .font(AppFont.zh(size: 10))
                    .foregroundStyle(on ? (p.isDark ? p.bg.opacity(0.7) : .white.opacity(0.75)) : p.inkMuted)
            }
            .foregroundStyle(on ? (p.isDark ? p.bg : .white) : p.inkSoft)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? p.ink : p.surface))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(on ? .clear : p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // Tells the user whether native audio is bundled yet. While recordings
    // are pending, everything runs on TTS and we're honest about it.
    private var statusLabel: String {
        let anyClip = SceneRepository.shared.scenes.contains {
            AudioLibrary.hasAnyNativeAudio(for: $0, voice: store.voice)
        }
        return anyClip ? "原声" : "暂用合成语音"
    }

    private func themeButton(mode: ThemeManager.Mode, label: String) -> some View {
        let p = theme.palette
        let on = theme.mode == mode
        return Button {
            Haptics.select()
            withAnimation(.easeInOut(duration: 0.28)) {
                theme.mode = mode
            }
        } label: {
            Text(label)
                .font(AppFont.zh(size: 12, weight: on ? .semibold : .medium))
                .foregroundStyle(on ? (p.isDark ? p.bg : .white) : p.inkSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(on ? p.ink : p.surface))
                .overlay(Capsule().stroke(on ? .clear : p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // 关于:用户协议 / 隐私政策入口(App Store 审核与国内监管都要求可点开)+ 版本号。
    private var aboutRows: some View {
        let p = theme.palette
        return VStack(spacing: 0) {
            aboutLink("用户协议", url: PrivacyConsent.termsURL)
            Divider().overlay(p.line)
            aboutLink("隐私政策", url: PrivacyConsent.privacyURL)
            Divider().overlay(p.line)
            HStack {
                Text("版本")
                    .font(AppFont.zh(size: 14))
                    .foregroundStyle(p.ink)
                Spacer()
                Text(PrivacyConsent.appVersionLabel)
                    .font(AppFont.enSans(size: 13))
                    .foregroundStyle(p.inkSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func aboutLink(_ title: String, url: URL) -> some View {
        let p = theme.palette
        return Link(destination: url) {
            HStack {
                Text(title)
                    .font(AppFont.zh(size: 14))
                    .foregroundStyle(p.ink)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(p.inkSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    // MARK: - Helpers

    private var avatarInitial: String { "学" }

    private var subtitleLine: String {
        "已开口 \(store.totalSentencesPracticed) 句 · 初级学习者"
    }

    private func heatColor(_ v: Int, p: Palette) -> Color {
        switch v {
        case 0:  return p.surfaceAlt
        case 1:  return p.sage.opacity(0.35)
        case 2:  return p.sage.opacity(0.65)
        default: return p.sage
        }
    }
}
