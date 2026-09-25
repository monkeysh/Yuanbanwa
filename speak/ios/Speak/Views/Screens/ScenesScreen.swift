import SwiftUI

struct ScenesScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    @State private var selectedCategory = "all"   // 日常话题
    @State private var selectedExam = "KET"        // 剑桥级别
    @State private var selectedTopic = "all"       // 剑桥话题
    @State private var query = ""

    // 分区来自 store.zone(首页双色块 / 下面板块切换决定)
    private var isCam: Bool { store.zone == "cambridge" }
    private var zoneAccent: Color { isCam ? theme.palette.cam : theme.palette.accent }

    private var allScenes: [SpeakScene] { SceneRepository.shared.scenes }
    private var dailyScenes: [SpeakScene] { allScenes.filter { $0.trackOrDaily == "daily" } }
    private var camScenes: [SpeakScene] { allScenes.filter { $0.isCambridge } }

    private func matchesQuery(_ s: SpeakScene) -> Bool {
        query.isEmpty
            || s.title.localizedCaseInsensitiveContains(query)
            || s.subtitle.localizedCaseInsensitiveContains(query)
    }

    private var filteredScenes: [SpeakScene] {
        if isCam {
            return camScenes.filter {
                $0.exam == selectedExam
                && (selectedTopic == "all" || $0.category == selectedTopic)
                && matchesQuery($0)
            }
        }
        return dailyScenes.filter {
            (selectedCategory == "all" || $0.category == selectedCategory) && matchesQuery($0)
        }
    }

    // 剑桥话题 chips:只显示当前级别下真实存在的话题
    private var examTopicChips: [SceneCategory] {
        let keys = Set(camScenes.filter { $0.exam == selectedExam }.map { $0.category })
        return [SceneCategory(key: "all", label: "全部")]
            + SceneRepository.shared.examTopics.filter { keys.contains($0.key) }
    }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                boardToggle
                searchField
                if isCam {
                    examSegment
                    completionBanner
                }
                chipRow
                sceneList
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isCam ? "CAMBRIDGE SPEAKING" : "EVERYDAY ENGLISH")
                .font(AppFont.enSans(size: 11, weight: .heavy)).tracking(1.6)
                .foregroundStyle(theme.palette.sun)
            Text("场景馆")
                .font(AppFont.enSerif(size: 30, weight: .bold))
                .foregroundStyle(theme.palette.ink)
            Text(isCam ? "剑桥口语话题，分级跟读，稳过考试" : "日常对话，跟着原声练，张口就来")
                .font(AppFont.zh(size: 13))
                .foregroundStyle(theme.palette.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - 板块切换(日常 / 剑桥)

    private var boardToggle: some View {
        segmented(
            options: [("daily", "日常对话"), ("cambridge", "剑桥考试")],
            selected: store.zone
        ) { key in
            withAnimation(.easeOut(duration: 0.18)) { store.zone = key }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var examSegment: some View {
        segmented(
            options: SceneRepository.shared.exams.map { ($0, $0) },
            selected: selectedExam
        ) { key in
            withAnimation(.easeOut(duration: 0.18)) { selectedExam = key; selectedTopic = "all" }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // 通用分段控件(外刊 .seg 风格:药丸容器 + 选中浮起)
    private func segmented(options: [(String, String)], selected: String,
                           onPick: @escaping (String) -> Void) -> some View {
        let p = theme.palette
        return HStack(spacing: 2) {
            ForEach(options, id: \.0) { key, label in
                let on = selected == key
                Button {
                    Haptics.select()
                    onPick(key)
                } label: {
                    Text(label)
                        .font(AppFont.zh(size: 13, weight: on ? .bold : .semibold))
                        .foregroundStyle(on ? zoneAccent : p.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(on ? p.surface : .clear)
                                .shadow(color: .black.opacity(on ? 0.12 : 0), radius: 3, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(p.surfaceAlt))
    }

    // MARK: - 搜索

    private var searchField: some View {
        let p = theme.palette
        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(p.inkMuted)
            TextField(isCam ? "搜索话题，如：购物、旅行" : "搜索场景，如：值机、点餐", text: $query)
                .font(AppFont.zh(size: 14))
                .foregroundStyle(p.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surfaceAlt)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - 备考完成度

    private var completionBanner: some View {
        let p = theme.palette
        let list = camScenes.filter { $0.exam == selectedExam }
        let total = list.count
        let done = list.filter { store.progress(for: $0.id) == 100 }.count
        let pct = total > 0 ? CGFloat(done) / CGFloat(total) : 0
        return VStack(spacing: 9) {
            HStack {
                Text("\(selectedExam) 备考完成度")
                    .font(AppFont.zh(size: 13, weight: .bold))
                    .foregroundStyle(p.ink)
                Spacer()
                Text("\(done)/\(total) 话题已完成")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkSoft)
            }
            Capsule().fill(p.surfaceAlt).frame(height: 6)
                .overlay(
                    GeometryReader { geo in
                        Capsule().fill(zoneAccent).frame(width: geo.size.width * pct)
                    }
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - 话题 chips

    private var chipRow: some View {
        let p = theme.palette
        let items = isCam ? examTopicChips : SceneRepository.shared.categories
        let selected = isCam ? selectedTopic : selectedCategory
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { cat in
                    let on = selected == cat.key
                    Button {
                        Haptics.select()
                        withAnimation(.easeOut(duration: 0.18)) {
                            if isCam { selectedTopic = cat.key } else { selectedCategory = cat.key }
                        }
                    } label: {
                        Text(cat.label)
                            .font(AppFont.zh(size: 13, weight: on ? .bold : .medium))
                            .foregroundStyle(on ? (p.isDark ? p.bg : .white) : p.inkSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(on ? p.ink : p.surfaceAlt))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
    }

    // MARK: - 场景列表

    private var sceneList: some View {
        VStack(spacing: 10) {
            if filteredScenes.isEmpty {
                Text(isCam ? "\(selectedExam) 话题对话正在陆续上线\n敬请期待 ✨" : "没有找到匹配的场景")
                    .font(AppFont.zh(size: 13))
                    .foregroundStyle(theme.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(filteredScenes) { scene in
                    sceneRow(scene)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func sceneRow(_ scene: SpeakScene) -> some View {
        let p = theme.palette
        let progress = store.progress(for: scene.id)
        return Button {
            Haptics.tap()
            path.append(AppRoute.detail(sceneId: scene.id))
        } label: {
            HStack(spacing: 14) {
                SceneGlyph(kind: scene.kind, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(scene.title)
                            .font(AppFont.zh(size: 15, weight: .semibold))
                            .foregroundStyle(p.ink)
                        if let exam = scene.exam {
                            examBadge(exam)
                        }
                        if scene.isNew {
                            Chip(text: "新", tone: .sun)
                        }
                    }
                    Text(scene.subtitle)
                        .font(AppFont.enSerif(size: 12))
                        .italic()
                        .foregroundStyle(p.inkMuted)
                        .padding(.bottom, 6)
                    HStack(spacing: 8) {
                        Text(scene.level)
                        Text("·").opacity(0.3)
                        Text("⏱ \(scene.minutes) 分钟")
                        Text("·").opacity(0.3)
                        Text("\(scene.sentenceCount) 句")
                    }
                    .font(AppFont.zh(size: 11))
                    .foregroundStyle(p.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if progress > 0 {
                    progressRing(progress: progress)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.surface)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(p.line, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func examBadge(_ exam: String) -> some View {
        Text(exam)
            .font(AppFont.enSans(size: 10, weight: .heavy))
            .foregroundStyle(theme.palette.cam)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(theme.palette.camSoft))
    }

    private func progressRing(progress: Int) -> some View {
        let p = theme.palette
        let color = progress == 100 ? p.sage : zoneAccent
        return ZStack {
            Circle().stroke(p.surfaceAlt, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(progress) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(progress == 100 ? "✓" : "\(progress)%")
                .font(AppFont.zh(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 36, height: 36)
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
