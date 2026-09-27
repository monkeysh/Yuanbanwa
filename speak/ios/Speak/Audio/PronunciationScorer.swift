import Foundation

// Scores a recognized utterance against a target sentence at the word level.
// Approach:
//   - Normalize both sides (lowercase, strip end punctuation, keep contractions)
//   - For each target word, find the closest recognized word in a sliding window
//   - Levenshtein distance drives a per-word score in [0…1]
// The goal isn't linguistic accuracy — it's to flag words the recognizer
// couldn't match so the UI can show "这几个词再来一次". For a commercial
// v1 we'd swap in a real phoneme engine (iFlytek / Tencent SOE native
// SDK) — the WebSocket-streaming route was explored and rolled back
// after hitting reliability issues with AVAudioEngine-based PCM capture
// on iOS 26; the native SDK route needs an actual SDK binary drop.

// SOE 真发音评测细节(音素级)。ScoreResult.soe != nil 时反馈卡走 SOE 呈现:
// 发音总分 + 准确/流利/完整三维 + 薄弱词音素;nil = 词匹配回落(旧呈现)。
struct SOEPhoneDetail: Equatable {
    let phone: String
    let accuracy: Double             // 0…100
}

struct SOEWordDetail: Equatable {
    let word: String
    let accuracy: Double             // 0…100
    let phones: [SOEPhoneDetail]
}

struct SOEDetail: Equatable {
    let accuracy: Int                // 发音准确度 0…100
    let fluency: Int                 // 流利度 0…100
    let completion: Int              // 完整度 0…100
    let words: [SOEWordDetail]
}

struct ScoreResult: Equatable {
    let overall: Int                 // 0…100
    let perWordScore: [Double]       // length == target.words.count, 0…1
    let weakIndexes: [Int]           // indexes where perWordScore < weakThreshold
    let recognized: String           // normalized recognized text (for debugging)
    let targetNormalized: [String]
    var soe: SOEDetail? = nil        // SOE 评测时携带;词匹配回落为 nil
}

enum PronunciationScorer {

    static let weakThreshold: Double = 0.65

    static func score(target: SceneSentence, recognized: String) -> ScoreResult {
        let targetWords = target.words.map(Self.normalize(_:))
        let recognizedWords = tokenize(recognized)

        guard !targetWords.isEmpty else {
            return ScoreResult(overall: 0, perWordScore: [], weakIndexes: [],
                               recognized: recognized.lowercased(), targetNormalized: [])
        }
        guard !recognizedWords.isEmpty else {
            return ScoreResult(overall: 0,
                               perWordScore: Array(repeating: 0, count: targetWords.count),
                               weakIndexes: Array(targetWords.indices),
                               recognized: "", targetNormalized: targetWords)
        }

        // For each target word, find the best-matching recognized word within a
        // ±2 word window around the aligned position. Keeps alignment stable
        // when the user misses a word or adds one.
        var used = Array(repeating: false, count: recognizedWords.count)
        var perWord: [Double] = []
        perWord.reserveCapacity(targetWords.count)

        let scale = Double(recognizedWords.count) / Double(targetWords.count)

        for (i, t) in targetWords.enumerated() {
            let center = Int((Double(i) + 0.5) * scale)
            let lo = max(0, center - 2)
            let hi = min(recognizedWords.count - 1, center + 2)

            var bestScore: Double = 0
            var bestIdx: Int? = nil
            for j in lo...hi {
                if used[j] { continue }
                let s = wordScore(target: t, recognized: recognizedWords[j])
                if s > bestScore {
                    bestScore = s
                    bestIdx = j
                }
            }
            if let idx = bestIdx, bestScore >= 0.55 {
                used[idx] = true
            }
            perWord.append(bestScore)
        }

        let avg = perWord.reduce(0, +) / Double(perWord.count)
        let overall = Int((avg * 100).rounded())
        let weak = perWord.enumerated()
            .filter { $0.element < weakThreshold }
            .map { $0.offset }

        return ScoreResult(
            overall: overall,
            perWordScore: perWord,
            weakIndexes: weak,
            recognized: recognizedWords.joined(separator: " "),
            targetNormalized: targetWords
        )
    }

    // MARK: - Word match

    // Exact match → 1.0. Near match (Levenshtein distance ≤ word length × 0.35) →
    // linear falloff. Anything further → 0. Tuned against the sample scenes.
    private static func wordScore(target: String, recognized: String) -> Double {
        if target == recognized { return 1.0 }
        let d = editDistance(target, recognized)
        let longer = max(target.count, recognized.count)
        guard longer > 0 else { return 0 }
        let ratio = Double(d) / Double(longer)
        // Forgiving for very short words where 1 edit = 100% ratio.
        if target.count <= 3 && d <= 1 { return 0.8 }
        if ratio < 0.2 { return 1.0 - ratio }
        if ratio < 0.35 { return 0.7 - (ratio - 0.2) * 1.2 }
        return 0
    }

    // Standard iterative Levenshtein. Unicode-safe because we work on
    // `Character` arrays.
    private static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a)
        let b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var curr = Array(repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            curr[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,        // deletion
                    curr[j - 1] + 1,    // insertion
                    prev[j - 1] + cost  // substitution
                )
            }
            swap(&prev, &curr)
        }
        return prev[b.count]
    }

    // MARK: - Normalization

    static func normalize(_ word: String) -> String {
        word.lowercased()
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"()[]"))
    }

    static func tokenize(_ s: String) -> [String] {
        s.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: CharacterSet(charactersIn: ".,!?;:\"()[]"))
                .filter { !$0.isEmpty } }
    }
}
