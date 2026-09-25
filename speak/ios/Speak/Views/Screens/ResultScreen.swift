import SwiftUI

struct ResultScreen: View {
    let scene: SpeakScene
    let tierLevel: String
    @Binding var path: NavigationPath
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    @State private var mounted = false

    // Pull sentences from the tier the user just practiced; fall back
    // to the default tier if the level string doesn't match (defensive
    // — shouldn't happen in practice).
    private var tier: SpeakSceneTier {
        scene.tier(level: tierLevel) ?? scene.defaultTier
    }

    private var bestSentence: SceneSentence? {
        tier.sentences.first { !$0.hasWeakWords } ?? tier.sentences.first
    }

    private var weakSentences: [SceneSentence] {
        tier.sentences.filter(\.hasWeakWords)
    }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                statsCard
                streakRow
                bestSentenceCard
                if !weakSentences.isEmpty {
                    reviewHint
                }
                actionButtons
            }
            .padding(.bottom, 40)
        }
        .background(p.bg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                mounted = true
            }
            Haptics.success()
        }
    }

    private var hero: some View {
        let p = theme.palette
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [p.sage, Color(red: 0.373, green: 0.494, blue: 0.376)],
                                         center: UnitPoint(x: 0.3, y: 0.3),
                                         startRadius: 0, endRadius: 80))
                    .frame(width: 110, height: 110)
                    .shadow(color: p.sage.opacity(0.35), radius: 24, y: 10)
                Image(systemName: "checkmark")
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .scaleEffect(mounted ? 1 : 0)
            .rotationEffect(.degrees(mounted ? 0 : -20))

            Text("今天已经开口了")
                .font(AppFont.zh(size: 24, weight: .semibold))
                .foregroundStyle(p.ink)
            Text("你完成了一个真实场景 · \(scene.title)")
                .font(AppFont.zh(size: 14))
                .foregroundStyle(p.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            LinearGradient(colors: [p.sageSoft, p.sageSoft.opacity(0)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private var statsCard: some View {
        let p = theme.palette
        struct Stat { let value: String; let label: String; let color: Color; let suffix: String? }
        let stats: [Stat] = [
            .init(value: "\(tier.sentenceCount)", label: "跟完句数", color: p.ink, suffix: nil),
            .init(value: "92", label: "平均相似度", color: p.accent, suffix: "%"),
            .init(value: "\(scene.minutes):12", label: "练习时长", color: p.ink, suffix: nil),
        ]
        return HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(stat.value)
                            .font(AppFont.enSans(size: 30, weight: .medium))
                            .foregroundStyle(stat.color)
                        if let s = stat.suffix {
                            Text(s)
                                .font(AppFont.enSans(size: 16, weight: .medium))
                                .foregroundStyle(stat.color)
                        }
                    }
                    Text(stat.label)
                        .font(AppFont.zh(size: 11))
                        .foregroundStyle(p.inkSoft)
                }
                .frame(maxWidth: .infinity)
                if i < stats.count - 1 {
                    Rectangle().fill(p.line).frame(width: 1, height: 28)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
        .padding(.top, -6)
    }

    private var streakRow: some View {
        let p = theme.palette
        return HStack(spacing: 14) {
            PlantIcon(day: store.streakDays + 1, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("连续 \(store.streakDays + 1) 天")
                    .font(AppFont.zh(size: 14, weight: .semibold))
                    .foregroundStyle(p.accentDeep)
                Text("明天继续，开口会越来越自然")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.accentDeep.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.accentSoft)
        )
        .padding(.horizontal, 20)
    }

    private var bestSentenceCard: some View {
        let p = theme.palette
        guard let best = bestSentence else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("表现最好的一句")
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(p.inkSoft)
                VStack(alignment: .leading, spacing: 10) {
                    Chip(text: "✓ 98% 相似", tone: .sage)
                    Text("\"\(best.en)\"")
                        .font(AppFont.enSerif(size: 20))
                        .italic()
                        .foregroundStyle(p.ink)
                    Text(best.zh)
                        .font(AppFont.zh(size: 12))
                        .foregroundStyle(p.inkSoft)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.surface)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(p.line, lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)
        )
    }

    private var reviewHint: some View {
        let p = theme.palette
        return Button {
            Haptics.tap()
            store.selectedTab = .review
            path.removeLast(path.count)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.accentSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(p.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weakSentences.count) 句建议明天复练")
                        .font(AppFont.zh(size: 14, weight: .semibold))
                        .foregroundStyle(p.ink)
                    Text("已加入复练队列")
                        .font(AppFont.zh(size: 12))
                        .foregroundStyle(p.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(p.inkMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(p.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(action: {
                Haptics.tap()
                store.selectedTab = .scenes
                path.removeLast(path.count)
            }) {
                Text("继续下一个场景")
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }

            GhostButton(action: {
                Haptics.tap()
                store.selectedTab = .home
                path.removeLast(path.count)
            }) {
                Text("回到首页")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}
