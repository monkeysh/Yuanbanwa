import SwiftUI

// 学习数据 S2:成长页区块(docs/DESIGN-学习数据板块-2026-07-31.md)。
// 数据全部来自 PracticeLogStore.growthStats() 的真实 session 日志——
// 无真分显示"未评分"/空柱,绝不编数(铲掉了旧 MeScreen 的假热力与硬编码总天数)。

// MARK: - 本周速览 4 格

struct WeekOverviewGrid: View {
    @EnvironmentObject var theme: ThemeManager
    let growth: GrowthStats
    let totalSentences: Int    // AppStore 旧聚合,与 session 日志并存

    var body: some View {
        let p = theme.palette
        let delta: String? = {
            guard let cur = growth.weekAvg, let prev = growth.prevWeekAvg else { return nil }
            let d = cur - prev
            return d == 0 ? "持平" : (d > 0 ? "↑\(d)" : "↓\(-d)")
        }()
        let items: [(String, String, String?)] = [
            ("\(growth.weekDays)", "本周天数", nil),
            ("\(growth.weekSentences)", "本周句数", nil),
            (growth.weekAvg.map(String.init) ?? "—", "平均发音分", delta),
            ("\(totalSentences)", "累计句数", nil),
        ]
        return HStack(spacing: 8) {
            ForEach(items, id: \.1) { item in
                VStack(spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(item.0)
                            .font(AppFont.enSans(size: 20, weight: .medium))
                            .foregroundStyle(p.ink)
                        if let d = item.2 {
                            Text(d)
                                .font(AppFont.zh(size: 10, weight: .semibold))
                                .foregroundStyle(d.hasPrefix("↑") ? p.sage : (d.hasPrefix("↓") ? p.danger : p.inkMuted))
                        }
                    }
                    Text(item.1)
                        .font(AppFont.zh(size: 10))
                        .foregroundStyle(p.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.line, lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 近 14 天发音趋势(手绘 Capsule 柱;无评分日空柱)

struct TrendBars: View {
    @EnvironmentObject var theme: ThemeManager
    let growth: GrowthStats

    var body: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("近 14 天发音趋势")
                    .font(AppFont.zh(size: 14, weight: .semibold))
                    .foregroundStyle(p.ink)
                Spacer()
                if let last = growth.daily14.last(where: { $0.avg != nil })?.avg {
                    Text("最近 \(last) 分")
                        .font(AppFont.zh(size: 11))
                        .foregroundStyle(p.inkMuted)
                }
            }
            if growth.daily14.allSatisfy({ $0.avg == nil }) {
                Text("练一组句子,这里就会长出你的发音曲线 🌱")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(growth.daily14.enumerated()), id: \.offset) { _, d in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Capsule()
                                .fill(d.avg == nil ? p.surfaceAlt : barColor(d.avg!, p: p))
                                // 40 分以下也给最矮可见高度;nil 给 4pt 占位
                                .frame(height: d.avg == nil ? 4 : max(8, CGFloat(d.avg! - 30) / 70 * 64))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 68)
                HStack {
                    Text(shortDay(growth.daily14.first?.day))
                    Spacer()
                    Text("今天")
                }
                .font(AppFont.zh(size: 10))
                .foregroundStyle(p.inkMuted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    private func barColor(_ avg: Int, p: Palette) -> Color {
        avg >= 85 ? p.sage : avg >= 70 ? p.accent : p.sun
    }
    private func shortDay(_ d: String?) -> String {
        guard let d, d.count == 10 else { return "" }
        return String(d.dropFirst(5)).replacingOccurrences(of: "-", with: "/")
    }
}

// MARK: - 场景地图(日常 + KET/PET/FCE,完成盖章)

struct SceneMapPanel: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    private struct Zone: Identifiable {
        let id: String
        let title: String
        let scenes: [SpeakScene]
    }

    private var zones: [Zone] {
        let all = SceneRepository.shared.scenes
        let daily = all.filter { ($0.track ?? "daily") != "cambridge" }
        func exam(_ e: String) -> [SpeakScene] { all.filter { $0.exam == e } }
        return [
            Zone(id: "daily", title: "日常对话", scenes: daily),
            Zone(id: "ket", title: "KET", scenes: exam("KET")),
            Zone(id: "pet", title: "PET", scenes: exam("PET")),
            Zone(id: "fce", title: "FCE", scenes: exam("FCE")),
        ]
    }

    var body: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 14) {
            Text("场景地图")
                .font(AppFont.zh(size: 14, weight: .semibold))
                .foregroundStyle(p.ink)
            ForEach(zones) { zone in
                let done = zone.scenes.filter { store.completedSceneIds.contains($0.id) }.count
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(zone.title)
                            .font(AppFont.zh(size: 12, weight: .medium))
                            .foregroundStyle(p.inkSoft)
                        Spacer()
                        Text("\(done)/\(zone.scenes.count)")
                            .font(AppFont.enSans(size: 12, weight: .medium))
                            .foregroundStyle(done == zone.scenes.count && done > 0 ? p.sage : p.inkMuted)
                    }
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 12)
                    LazyVGrid(columns: cols, spacing: 5) {
                        ForEach(zone.scenes) { sc in
                            let completed = store.completedSceneIds.contains(sc.id)
                            let started = (store.sceneProgress[sc.id] ?? 0) > 0
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(completed ? p.sage : started ? p.sage.opacity(0.35) : p.surfaceAlt)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                legendDot(p.sage, "已完成", p: p)
                legendDot(p.sage.opacity(0.35), "进行中", p: p)
                legendDot(p.surfaceAlt, "未开始", p: p)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(p.line, lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    private func legendDot(_ c: Color, _ label: String, p: Palette) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 8, height: 8)
            Text(label).font(AppFont.zh(size: 10)).foregroundStyle(p.inkMuted)
        }
    }
}

// MARK: - 模拟考官记录(最近 5 轮)

struct ExamLogPanel: View {
    @EnvironmentObject var theme: ThemeManager
    let growth: GrowthStats

    var body: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 10) {
            Text("模拟考官记录")
                .font(AppFont.zh(size: 14, weight: .semibold))
                .foregroundStyle(p.ink)
            if growth.recentExams.isEmpty {
                Text("还没考过 — 去场景馆找「模拟考官」来一轮吧 🎙️")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
            } else {
                ForEach(growth.recentExams) { s in
                    HStack(spacing: 10) {
                        Text(s.tierLevel)   // exam session 里 tierLevel 存 KET/PET/FCE
                            .font(AppFont.enSans(size: 11, weight: .semibold))
                            .foregroundStyle(p.accent)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(p.accent.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.examTopicZh ?? s.sceneId)
                                .font(AppFont.zh(size: 13, weight: .medium))
                                .foregroundStyle(p.ink)
                                .lineLimit(1)
                            Text("\(s.sentenceCount) 问 · \(String(s.day.dropFirst(5)).replacingOccurrences(of: "-", with: "/"))")
                                .font(AppFont.zh(size: 10))
                                .foregroundStyle(p.inkMuted)
                        }
                        Spacer()
                        // 有真实 SOE 分才显示;全程降级 → 「未评分」,不编分
                        Text(s.avgOverall.map { "\($0) 分" } ?? "未评分")
                            .font(AppFont.zh(size: 12, weight: .semibold))
                            .foregroundStyle(s.avgOverall == nil ? p.inkMuted : p.ink)
                    }
                    .padding(.vertical, 4)
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
}
