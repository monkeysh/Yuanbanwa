import Foundation

// Data models mirroring scenes.json. Decode once at launch; the repo keeps
// them in memory as the single source of truth for the UI.

struct SceneCategory: Codable, Hashable, Identifiable {
    let key: String
    let label: String
    var id: String { key }
}

struct SceneSentence: Codable, Hashable, Identifiable {
    let en: String
    let zh: String
    let words: [String]
    let weak: [Int]

    // Optional native-speaker clip filenames keyed by voice id.
    // e.g. {"rosie": "rosie/starbucks_01.mp3", "chris": "chris/..."}
    // Missing entry = SpeechSpeaker falls back to TTS.
    let audio: [String: String]?
    // 该句指定声线(男女双线对话:男声轮=chris);缺省 nil → rosie(女)。
    let voice: String?

    var id: String { en }
    var hasWeakWords: Bool { !weak.isEmpty }
    /// 播放用的声线:该句指定的 → 否则 Rosie。
    var preferredVoice: VoicePreference {
        VoicePreference(rawValue: voice ?? "") ?? .rosie
    }
}

// One difficulty tier inside a scene. Every scene has at least one
// (we pre-wrap legacy single-list scenes as a single 初级 tier in
// seed-tiers.py so the iOS code only ever has to deal with this shape).
struct SpeakSceneTier: Codable, Hashable, Identifiable {
    let level: String             // entry / beginner / intermediate / advanced
    let label: String             // 入门 / 初级 / 中级 / 高级
    let sentenceCount: Int
    let sentences: [SceneSentence]
    var id: String { level }
}

struct SpeakScene: Codable, Hashable, Identifiable {
    let id: String
    let kind: String              // travel / life / social / urgent / school
    let category: String          // filter key — matches SceneCategory.key
    let title: String
    let subtitle: String
    let level: String             // 初级 / 中级 / 高级 (catalog-level placeholder)
    let minutes: Int
    let sentenceCount: Int        // sum across tiers; legacy field
    let progress: Int             // 0…100 (seed value from JSON; live progress tracked in AppStore)
    let isNew: Bool
    let isFeatured: Bool          // marks the day's hero scene
    let description: String
    let learn: [String]
    let tiers: [SpeakSceneTier]
    // 双板块 / 剑桥分级（H5 新增；daily 场景缺省这两个字段）
    let track: String?            // "daily"(默认) / "cambridge"
    let exam: String?             // 剑桥场景: "KET" / "PET" / "FCE"
    // 剑桥备考三件套(仅 cambridge 场景;daily 缺省)
    let examPart: String?         // Part 标注,如 "Part 1 + Part 2" / "话题拓展｜生活场景口语"
    let examTip: String?          // 考点说明(中文)
    let templates: [AnswerTemplate]?  // 答题锦囊·万能句型
}

// 答题模板:en 带 ___ 空的句型,zh 用途说明
struct AnswerTemplate: Codable, Hashable {
    let en: String
    let zh: String
}

extension SpeakScene {
    /// 板块归属（缺省视为日常对话）
    var trackOrDaily: String { track ?? "daily" }
    var isCambridge: Bool { track == "cambridge" }

    /// Convenience: the 初级 tier (always present), or whichever tier
    /// the caller falls back to. Used by the home / scenes screens that
    /// don't yet know which tier the user picked.
    var defaultTier: SpeakSceneTier {
        tiers.first(where: { $0.level == "beginner" }) ?? tiers.first ?? SpeakSceneTier(
            level: "beginner", label: "初级", sentenceCount: 0, sentences: []
        )
    }

    func tier(level: String) -> SpeakSceneTier? {
        tiers.first(where: { $0.level == level })
    }
}

struct SceneCatalog: Codable {
    let version: Int
    let categories: [SceneCategory]
    let scenes: [SpeakScene]
    let examTopics: [SceneCategory]?   // 剑桥话题 chips（H5 新增顶层字段）
}

// ReviewItem tracks a single weak-spot sentence for the 复练 tab.
// `tierLevel` was added when we split scenes into 4 difficulty tiers;
// rows persisted from before that point default to "beginner" via the
// migration in AppStore.loadReviewQueue.
struct ReviewItem: Hashable, Identifiable {
    let sceneId: String
    let tierLevel: String         // entry / beginner / intermediate / advanced
    let sentenceIndex: Int
    var id: String { "\(sceneId)#\(tierLevel)#\(sentenceIndex)" }
}
