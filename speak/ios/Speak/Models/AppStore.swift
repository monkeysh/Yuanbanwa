import Foundation
import SwiftUI

// Global observable state: current tab, review queue, progress per scene.
// Persists to UserDefaults for v0.1; move to SwiftData once we need
// richer per-sentence history.

@MainActor
final class AppStore: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var reviewQueue: [ReviewItem]
    @Published var sceneProgress: [String: Int]   // scene.id -> 0…100
    @Published var streakDays: Int
    @Published var totalSentencesPracticed: Int
    @Published var completedSceneIds: Set<String>
    private var lastPracticeDay: String = ""   // "yyyy-MM-dd" 本地,判断连续打卡
    @Published var voice: VoicePreference {
        didSet { UserDefaults.standard.set(voice.rawValue, forKey: "voice") }
    }
    // 当前分区(运行时,不持久化):首页双色块 / 场景馆分段决定。
    // "daily" 陶土橙日常 / "cambridge" 墨蓝剑桥。
    @Published var zone: String = "daily"

    enum Tab: String, Hashable {
        case home, scenes, review, me
    }

    init() {
        // Real review queue only — previously we seeded 5 fake items on
        // first launch ("starbucks:0, starbucks:2, self-intro:2, ...") so
        // the tab wasn't empty. That leaked into real use: new users saw
        // sentences they'd never practiced, and emptying the queue caused
        // the seed to reload on next launch. Now: empty until the user
        // actually practices.
        var loaded = AppStore.loadReviewQueue()
        // One-time migration: if this install still has the exact v0.1
        // seed sitting in UserDefaults, wipe it. Uses a flag so we don't
        // keep comparing every launch.
        if !UserDefaults.standard.bool(forKey: "migrated_seed_v0_1") {
            let seedKeys: Set<String> = ["starbucks:0", "starbucks:2", "self-intro:2", "self-intro:5", "restaurant:5"]
            let currentKeys = Set(loaded.map { "\($0.sceneId):\($0.sentenceIndex)" })
            if currentKeys == seedKeys { loaded = [] }
            UserDefaults.standard.set(true, forKey: "migrated_seed_v0_1")
        }
        self.reviewQueue = loaded

        self.sceneProgress = UserDefaults.standard.dictionary(forKey: "sceneProgress") as? [String: Int] ?? [:]
        // streakDays was seeded to 12 for first-run "polish" — misleading
        // for a real user. Start at 0 until they practice.
        self.streakDays = UserDefaults.standard.integer(forKey: "streakDays")
        self.totalSentencesPracticed = UserDefaults.standard.integer(forKey: "totalSentencesPracticed")
        let completedList = UserDefaults.standard.stringArray(forKey: "completedSceneIds") ?? []
        self.completedSceneIds = Set(completedList)
        self.lastPracticeDay = UserDefaults.standard.string(forKey: "lastPracticeDay") ?? ""
        // 2026-07 全站换 Rosie:旧声线音频已不打包,存量选择一律迁到 rosie。
        let savedVoice = UserDefaults.standard.string(forKey: "voice") ?? VoicePreference.rosie.rawValue
        let decoded = VoicePreference(rawValue: savedVoice) ?? .rosie
        self.voice = VoicePreference.available.contains(decoded) ? decoded : .rosie
    }

    func progress(for sceneId: String) -> Int {
        sceneProgress[sceneId] ?? SceneRepository.shared.scene(id: sceneId)?.progress ?? 0
    }

    func recordPractice(scene: SpeakScene, tier: SpeakSceneTier,
                        sentencesCompleted: Int, weakIndexes: [Int]) {
        updateStreak()   // 修复:此前从不更新 streakDays,连续天数永远 0
        totalSentencesPracticed += sentencesCompleted
        let denom = max(1, tier.sentenceCount)
        let bumped = min(100, (sceneProgress[scene.id] ?? 0) + sentencesCompleted * 100 / denom)
        sceneProgress[scene.id] = bumped
        if bumped >= 100 {
            completedSceneIds.insert(scene.id)
        }
        // Merge weak spots into the review queue, deduped per (scene, tier).
        let existing = Set(
            reviewQueue
                .filter { $0.sceneId == scene.id && $0.tierLevel == tier.level }
                .map { $0.sentenceIndex }
        )
        let additions = weakIndexes
            .filter { !existing.contains($0) }
            .map { ReviewItem(sceneId: scene.id, tierLevel: tier.level, sentenceIndex: $0) }
        reviewQueue.append(contentsOf: additions)
        persist()
    }

    // 连续打卡:今天首次练习时更新。昨天练过→+1;断签/首次→重置为 1;今天已练→不变。
    private func updateStreak() {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let today = Date()
        let todayStr = fmt.string(from: today)
        if lastPracticeDay == todayStr { return }   // 今天已打卡,不重复计
        if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
           lastPracticeDay == fmt.string(from: yesterday) {
            streakDays += 1                          // 昨天练过 → 连续 +1
        } else {
            streakDays = 1                           // 首次或断签 → 今天算第 1 天
        }
        lastPracticeDay = todayStr
    }

    // 学习数据 S1:一次练习结束落一条 session 明细(聚合在 PracticeSession.build,
    // 落盘在 PracticeLogStore 的串行队列)。与 recordPractice 旧聚合字段并存互不影响。
    func logSession(sceneId: String, tierLevel: String, mode: String,
                    sentenceCount: Int, scored: [(overall: Int, soe: SOEDetail)],
                    startedAt: Date, examTopicZh: String? = nil) {
        PracticeLogStore.append(PracticeSession.build(
            sceneId: sceneId, tierLevel: tierLevel, mode: mode,
            sentenceCount: sentenceCount, scored: scored,
            startedAt: startedAt,
            durationSec: Int(Date().timeIntervalSince(startedAt)),
            examTopicZh: examTopicZh
        ))
    }

    func clearFromReviewQueue(sceneId: String, tierLevel: String, sentenceIndexes: [Int]) {
        let dropped = Set(sentenceIndexes)
        reviewQueue.removeAll {
            $0.sceneId == sceneId
                && $0.tierLevel == tierLevel
                && dropped.contains($0.sentenceIndex)
        }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(sceneProgress, forKey: "sceneProgress")
        UserDefaults.standard.set(streakDays, forKey: "streakDays")
        UserDefaults.standard.set(totalSentencesPracticed, forKey: "totalSentencesPracticed")
        UserDefaults.standard.set(Array(completedSceneIds), forKey: "completedSceneIds")
        UserDefaults.standard.set(lastPracticeDay, forKey: "lastPracticeDay")
        // Serialize as [[sceneId, tierLevel, sentenceIndex]] — three strings per
        // row. Old two-string rows from before tiers existed are migrated by
        // loadReviewQueue (defaults to "beginner").
        let queueRaw = reviewQueue.map { [$0.sceneId, $0.tierLevel, String($0.sentenceIndex)] }
        UserDefaults.standard.set(queueRaw, forKey: "reviewQueue")
    }

    private static func loadReviewQueue() -> [ReviewItem] {
        guard let raw = UserDefaults.standard.array(forKey: "reviewQueue") as? [[String]] else { return [] }
        return raw.compactMap { row -> ReviewItem? in
            // 3-element rows are post-tier; 2-element rows are legacy and
            // get migrated to "beginner" tier (which is where every existing
            // review item lived before the schema change).
            if row.count == 3, let idx = Int(row[2]) {
                return ReviewItem(sceneId: row[0], tierLevel: row[1], sentenceIndex: idx)
            }
            if row.count == 2, let idx = Int(row[1]) {
                return ReviewItem(sceneId: row[0], tierLevel: "beginner", sentenceIndex: idx)
            }
            return nil
        }
    }
}
