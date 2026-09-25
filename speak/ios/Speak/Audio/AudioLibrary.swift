import Foundation

// Resolves native-speaker audio clips shipped in the app bundle.
// 产品声线:Rosie(女) + Chris(男)。历史声线 bella/alice/george 已清理。
// 新增声线纯增量:加 case、生成 mp3 放 Speak/Resources/audio/<voice>/、scenes.json 同 key。

enum VoicePreference: String, CaseIterable, Codable {
    case rosie   // US female · 女声主声线(外刊精读同款)
    case chris   // US male · 男声(对话男声轮 / 男考官)

    /// 产品可选声线:女 Rosie / 男 Chris
    static var available: [VoicePreference] { [.rosie, .chris] }

    var displayName: String {
        switch self {
        case .rosie:  return "美式 · Rosie"
        case .chris:  return "美式 · Chris"
        }
    }

    var shortName: String {
        switch self {
        case .rosie:  return "Rosie"
        case .chris:  return "Chris"
        }
    }

    var accentBadge: String { "🇺🇸" }

    var genderBadge: String {
        switch self {
        case .rosie:  return "女声"
        case .chris:  return "男声"
        }
    }

    // For the TTS fallback when a clip is missing.
    var fallbackLocale: String { "en-US" }
}

enum AudioLibrary {

    static func clipURL(for sentence: SceneSentence, voice: VoicePreference) -> URL? {
        guard let path = sentence.audio?[voice.rawValue] else { return nil }

        // Path is relative to the bundle's audio/ directory:
        //   "bella/starbucks_01.mp3" → audio/bella/starbucks_01.mp3
        let components = path.split(separator: "/")
        guard let last = components.last else { return nil }
        let name = (String(last) as NSString).deletingPathExtension
        let parsedExt = (String(last) as NSString).pathExtension
        let ext = parsedExt.isEmpty ? "mp3" : parsedExt
        let subdir = components.count > 1
            ? "audio/" + components.dropLast().joined(separator: "/")
            : "audio"

        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir)
    }

    static func hasAnyNativeAudio(for scene: SpeakScene, voice: VoicePreference) -> Bool {
        scene.tiers.flatMap(\.sentences).contains { sentence in
            clipURL(for: sentence, voice: voice) != nil
        }
    }
}
