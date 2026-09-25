import SwiftUI

struct HomeScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthManager

    private var continueScene: SpeakScene {
        SceneRepository.shared.scene(id: "restaurant") ?? SceneRepository.shared.scenes[1]
    }

    var body: some View {
        let p = theme.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                greeting
                streakPill
                zoneBlock(cam: false)   // 日常 · 陶土橙
                zoneBlock(cam: true)    // 剑桥 · 墨蓝
                continueRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 60)
        }
        .background(p.bg.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .navigationDestination(for: AppRoute.self) { route in
            destination(for: route)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { toggleTheme() } label: {
                    // Reflect the *current* palette (including when mode ==
                    // .system resolves to dusk via OS dark mode) rather than
                    // the stored Mode — otherwise the icon disagrees with
                    // the visuals for system-followers.
                    Image(systemName: theme.palette.isDark ? "moon.stars.fill" : "sun.max.fill")
                        .foregroundStyle(theme.palette.inkSoft)
                }
            }
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateLine)
                .font(AppFont.zh(size: 13))
                .foregroundStyle(theme.palette.inkSoft)
                .tracking(0.5)
            Text("早上好，\(auth.account?.nickname ?? "学员")")
                .font(AppFont.enSerif(size: 28, weight: .bold))
                .foregroundStyle(theme.palette.ink)
            HStack(spacing: 0) {
                Text("今天也开口 ")
                Text("5 分钟").foregroundStyle(theme.palette.ink).fontWeight(.semibold)
                Text("，挑一个分区练起来")
            }
            .font(AppFont.zh(size: 15))
            .foregroundStyle(theme.palette.inkSoft)
            .padding(.top, 2)
        }
        .padding(.bottom, 18)
    }

    private var streakPill: some View {
        HStack(spacing: 10) {
            PlantIcon(day: store.streakDays, size: 24)
            Text("连续 \(store.streakDays) 天")
                .font(AppFont.zh(size: 13.5, weight: .semibold))
                .foregroundStyle(theme.palette.ink)
            Text("· 再坚持 \(max(0, 14 - store.streakDays)) 天满两周")
                .font(AppFont.zh(size: 12))
                .foregroundStyle(theme.palette.inkMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(theme.palette.surface)
                .overlay(Capsule().stroke(theme.palette.line, lineWidth: 1))
        )
        .padding(.bottom, 16)
    }

    // 场景数(分区块 stat 用)
    private var dailyCount: Int { SceneRepository.shared.scenes.filter { $0.trackOrDaily == "daily" }.count }
    private var camCount: Int { SceneRepository.shared.scenes.filter { $0.isCambridge }.count }

    // 首页双色块入口(方案 B 画刊):陶土橙日常 / 墨蓝剑桥,点击进各自分区
    private func zoneBlock(cam: Bool) -> some View {
        let eyebrow = cam ? "CAMBRIDGE SPEAKING" : "EVERYDAY ENGLISH"
        let title   = cam ? "剑桥考试对话" : "日常对话跟读"
        let sub     = cam ? "KET · PET · FCE 口语，考点跟读、备考冲刺"
                          : "生活 · 出行 · 社交 · 学校 · 紧急，跟着原声开口"
        let stat    = cam ? "KET · PET · FCE 三级 · \(camCount) 话题"
                          : "\(dailyCount) 个场景 · 零基础友好"
        let glyph   = cam ? "graduationcap.fill" : "bubble.left.and.bubble.right.fill"
        let grad = cam
            ? LinearGradient(colors: [Color(hex: "34678a"), Color(hex: "244c66"), Color(hex: "173241")],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color(hex: "c2724a"), Color(hex: "9a5230"), Color(hex: "80421f")],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
        let shadowColor = cam ? Color(hex: "1e3d54") : Color(hex: "8c4c2c")
        return Button {
            Haptics.tap()
            store.zone = cam ? "cambridge" : "daily"
            store.selectedTab = .scenes
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: glyph)
                    .font(.system(size: 128))
                    .foregroundStyle(.white.opacity(0.12))
                    .rotationEffect(.degrees(-6))
                    .offset(x: 24, y: 18)
                VStack(alignment: .leading, spacing: 0) {
                    Text(eyebrow)
                        .font(AppFont.enSans(size: 10.5, weight: .heavy)).tracking(1.6)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(title)
                        .font(AppFont.enSerif(size: 25, weight: .bold))
                        .foregroundStyle(.white).padding(.top, 7)
                    Text(sub)
                        .font(AppFont.zh(size: 13)).foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
                    HStack {
                        Text(stat)
                            .font(AppFont.zh(size: 11.5, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))
                        Spacer()
                        HStack(spacing: 6) {
                            Text("进入")
                            Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                        }
                        .font(AppFont.zh(size: 12.5, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.18)))
                    }
                    .padding(.top, 17)
                }
                .padding(.horizontal, 20).padding(.vertical, 21)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(grad)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: shadowColor.opacity(0.55), radius: 22, y: 14)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 13)
    }

    private var continueRow: some View {
        let p = theme.palette
        return Button {
            Haptics.tap()
            path.append(AppRoute.detail(sceneId: continueScene.id))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.sageSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill").font(.system(size: 14))
                        .foregroundStyle(p.sage)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("继续昨天 · \(continueScene.title)")
                        .font(AppFont.zh(size: 14, weight: .semibold))
                        .foregroundStyle(p.ink)
                    Text("还剩 3 句没跟完")
                        .font(AppFont.zh(size: 12))
                        .foregroundStyle(p.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(p.inkMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.surface)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(p.line, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    private func toggleTheme() {
        Haptics.select()
        withAnimation(.easeInOut(duration: 0.28)) {
            theme.mode = (theme.mode == .cream) ? .dusk : .cream
        }
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
