import SwiftUI

struct ReviewScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    private struct Group: Identifiable {
        let scene: SpeakScene
        let tier: SpeakSceneTier
        let indexes: [Int]
        var id: String { "\(scene.id)#\(tier.level)" }
    }

    // Group review items by (scene, tier) so each card shows weak
    // sentences from the same difficulty bucket. A user practicing 中级
    // shouldn't see their 高级 misses bundled in.
    private var grouped: [Group] {
        struct Key: Hashable { let sceneId: String; let tierLevel: String }
        let byKey = Dictionary(grouping: store.reviewQueue) {
            Key(sceneId: $0.sceneId, tierLevel: $0.tierLevel)
        }
        return byKey.compactMap { (key, items) -> Group? in
            guard let scene = SceneRepository.shared.scene(id: key.sceneId),
                  let tier = scene.tier(level: key.tierLevel) else { return nil }
            let sortedIndexes = items.map(\.sentenceIndex).sorted()
            return Group(scene: scene, tier: tier, indexes: sortedIndexes)
        }
        .sorted {
            if $0.scene.title != $1.scene.title { return $0.scene.title < $1.scene.title }
            return $0.tier.level < $1.tier.level
        }
    }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                summaryCard
                if store.reviewQueue.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped) { group in
                        groupSection(group)
                    }
                }
            }
            .padding(.bottom, 60)
        }
        .background(p.bg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationDestination(for: AppRoute.self) { route in
            destination(for: route)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("复练")
                .font(AppFont.zh(size: 28, weight: .semibold))
                .foregroundStyle(theme.palette.ink)
            Text("把卡住的几句再来一遍，比新学十句都划算")
                .font(AppFont.zh(size: 13))
                .foregroundStyle(theme.palette.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var summaryCard: some View {
        let p = theme.palette
        let count = store.reviewQueue.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("待复练")
                .font(AppFont.zh(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(p.accentDeep)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(AppFont.enSans(size: 36, weight: .medium))
                    .foregroundStyle(p.ink)
                Text("句")
                    .font(AppFont.zh(size: 14))
                    .foregroundStyle(p.inkSoft)
            }
            Text(count > 0
                 ? "来自 \(grouped.count) 个场景 · 约 \(max(2, count)) 分钟"
                 : "今天暂无错句 — 继续练新场景吧")
                .font(AppFont.zh(size: 12))
                .foregroundStyle(p.accentDeep.opacity(0.75))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(
                    colors: [p.accentSoft, p.sageSoft.opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        let p = theme.palette
        return VStack(spacing: 16) {
            ZStack {
                Circle().fill(p.sageSoft).frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(p.sage)
            }
            .padding(.top, 28)
            Text("清空了！")
                .font(AppFont.zh(size: 15, weight: .semibold))
                .foregroundStyle(p.ink)
            Text("错句会在练习后自动进来 — 去练一个新场景。")
                .font(AppFont.zh(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(p.inkSoft)
            Button {
                Haptics.tap()
                store.selectedTab = .scenes
            } label: {
                Text("去场景馆")
                    .font(AppFont.zh(size: 13, weight: .semibold))
                    .foregroundStyle(p.isDark ? p.bg : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(p.ink))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func groupSection(_ group: Group) -> some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SceneGlyph(kind: group.scene.kind, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(group.scene.title)
                            .font(AppFont.zh(size: 14, weight: .semibold))
                            .foregroundStyle(p.ink)
                        // Tier label so the user knows which bucket the
                        // weak sentences are from. Only renders for
                        // multi-tier scenes — single-tier scenes are
                        // visually quieter.
                        if group.scene.tiers.count > 1 {
                            Text(group.tier.label)
                                .font(AppFont.zh(size: 10, weight: .semibold))
                                .foregroundStyle(p.accentDeep)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(p.accentSoft))
                        }
                    }
                    Text("\(group.indexes.count) 句待复练")
                        .font(AppFont.zh(size: 11))
                        .foregroundStyle(p.inkMuted)
                }
                Spacer()
                Button {
                    Haptics.tap()
                    path.append(AppRoute.practice(sceneId: group.scene.id,
                                                   tierLevel: group.tier.level,
                                                   filteredIndexes: group.indexes))
                } label: {
                    HStack(spacing: 4) {
                        Text("一起练")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                    }
                    .font(AppFont.zh(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(p.accent))
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 8) {
                ForEach(group.indexes, id: \.self) { idx in
                    if let sent = group.tier.sentences[safe: idx] {
                        sentenceRow(scene: group.scene, tier: group.tier,
                                    sentenceIdx: idx, sentence: sent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func sentenceRow(scene: SpeakScene, tier: SpeakSceneTier,
                             sentenceIdx: Int, sentence: SceneSentence) -> some View {
        let p = theme.palette
        return Button {
            Haptics.tap()
            path.append(AppRoute.practice(sceneId: scene.id,
                                           tierLevel: tier.level,
                                           filteredIndexes: [sentenceIdx]))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sentence.en)
                        .font(AppFont.enSerif(size: 15))
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                    Text(sentence.zh)
                        .font(AppFont.zh(size: 11.5))
                        .foregroundStyle(p.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().fill(p.accentSoft).frame(width: 32, height: 32)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(p.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.line, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .detail(let id):
            if let scene = SceneRepository.shared.scene(id: id) {
                SceneDetailScreen(scene: scene, path: $path)
            }
        case .practice(let id, let tierLevel, let indexes):
            if let scene = SceneRepository.shared.scene(id: id) {
                let tier = scene.tier(level: tierLevel) ?? scene.defaultTier
                PracticeScreen(scene: scene, tier: tier, filteredIndexes: indexes, path: $path)
            }
        case .drill(let id, let tierLevel, let userVoice):
            if let scene = SceneRepository.shared.scene(id: id) {
                let tier = scene.tier(level: tierLevel) ?? scene.defaultTier
                PracticeScreen(scene: scene, tier: tier, filteredIndexes: nil,
                               drillUserVoice: userVoice, path: $path)
            }
        case .exam(let exam, let topic, let topicZh, let ev):
            ExamScreen(exam: exam, topic: topic, topicZh: topicZh, examinerVoice: ev, path: $path)
        case .result(let id, let tierLevel):
            if let scene = SceneRepository.shared.scene(id: id) {
                ResultScreen(scene: scene, tierLevel: tierLevel, path: $path)
            }
        }
    }
}
