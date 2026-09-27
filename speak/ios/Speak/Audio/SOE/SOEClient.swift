//
//  SOEClient.swift
//  发音评测客户端:录音 WAV → 16k PCM → POST 同域代理 /api/soe → 腾讯云口语评测(SOE)。
//  凭据只放在服务器 .env;App 不再内嵌 SecretId/SecretKey,也不再链接腾讯原生 SDK。
//  Web 端 index.html 的 Pron 模块走的是同一个接口、同一份返回格式(server normalize 后的扁平 JSON)。
//

import Foundation

/// SOE 整句评测结果
struct SOEResult {
    let pronAccuracy: Double    // 发音准确度 0–100
    let pronFluency: Double     // 流利度 0–1
    let pronCompletion: Double  // 完整度 0–1;自由说模式下腾讯返回 -1(不适用),调用方须剔除
    let suggestedScore: Double  // 综合建议分 0–100
    let words: [SOEWord]
}

struct SOEWord {
    let word: String
    let accuracy: Double        // 0–100
    let matchTag: Int           // 代理接口暂不返回 MatchTag,固定 0;UI 未使用
    let phones: [SOEPhoneDetail] // 音素级得分,英文引擎才有
}

enum SOEError: LocalizedError {
    case noResult
    case tooLong
    case rateLimited
    case failed(String)
    var errorDescription: String? {
        switch self {
        case .noResult: return "评测无结果"
        case .tooLong: return "录音过长(超过约 30 秒),本句未评分"
        case .rateLimited: return "评测服务繁忙,请稍后再试"
        case .failed(let m): return m
        }
    }
}

enum SOEClient {
    /// 评测口径。
    /// - sentence:跟读用。有明确目标句,完整度(说全了没有)是有效的惩罚维度。
    /// - freeSpeak:开放式作答(模拟考官)用。学生的话没有标准答案,不吃参考文本,只评发音本身。
    enum Mode {
        case sentence
        case freeSpeak
        var evalMode: Int { self == .freeSpeak ? 3 : 1 }
    }

    static let endpoint = URL(string: "https://speak.yuanbanwa.top/api/soe")!
    /// 严格度系数(1.0 最宽松 … 4.0 最严格)。沿用原生 SDK 时期的实测取值 3.0:
    /// 含糊快读 1.0→94.4 / 2.0→92.5 / 3.0→88.4 / 4.0→73.5,而正常朗读 3.0 仍有 96.9。
    static let scoreCoeff: Double = 3.0
    /// nginx 对 /api/soe 的请求体上限是 1400k;base64 后约 1MB 原始 PCM ≈ 32 秒 16k/16bit 单声道。
    static let maxPCMBytes = 1_000_000
    private static let wavHeaderBytes = 44
    private static let timeoutSeconds: TimeInterval = 30

    /// 对外入口:传录音 WAV 文件(16kHz 单声道 16-bit PCM,SpeechRecorder 产出)+ 目标英文句,异步返回真分。
    static func evaluate(wavURL: URL, refText: String, mode: Mode = .sentence) async throws -> SOEResult {
        let wav = try Data(contentsOf: wavURL)
        guard wav.count > wavHeaderBytes else { throw SOEError.noResult }
        let pcm = wav.subdata(in: wavHeaderBytes..<wav.count)
        return try await evaluate(pcm16k: pcm, refText: refText, mode: mode)
    }

    static func evaluate(pcm16k: Data, refText: String, mode: Mode) async throws -> SOEResult {
        guard pcm16k.count <= maxPCMBytes else { throw SOEError.tooLong }
        let body: [String: Any] = [
            "refText": refText,
            "voiceData": pcm16k.base64EncodedString(),
            "evalMode": mode.evalMode,
            "coeff": scoreCoeff,
        ]
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = timeoutSeconds
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        if status == 429 { throw SOEError.rateLimited }
        if let message = obj?["error"] as? String, !message.isEmpty { throw SOEError.failed(message) }
        guard status == 200, let obj, (obj["parsed"] as? Bool) == true else {
            throw SOEError.failed("评测服务异常(HTTP \(status))")
        }
        return parse(obj)
    }

    // MARK: - 解析(服务器 normalize 后的字段名,与 Web 端一致)
    static func parse(_ obj: [String: Any]) -> SOEResult {
        func num(_ dict: [String: Any], _ key: String) -> Double {
            if let n = dict[key] as? NSNumber { return n.doubleValue }
            return 0
        }
        let acc = num(obj, "pronAccuracy")
        let flu = num(obj, "pronFluency")
        let comp = num(obj, "pronCompletion")
        var sug = num(obj, "suggestedScore")
        if sug == 0 { sug = acc }
        var words: [SOEWord] = []
        if let arr = obj["words"] as? [[String: Any]] {
            for w in arr {
                let word = (w["word"] as? String) ?? ""
                var phones: [SOEPhoneDetail] = []
                if let parr = w["phones"] as? [[String: Any]] {
                    for p in parr {
                        let ph = (p["phone"] as? String) ?? ""
                        guard !ph.isEmpty else { continue }
                        phones.append(SOEPhoneDetail(phone: ph, accuracy: num(p, "accuracy")))
                    }
                }
                words.append(SOEWord(word: word, accuracy: num(w, "accuracy"), matchTag: 0, phones: phones))
            }
        }
        return SOEResult(pronAccuracy: acc, pronFluency: flu, pronCompletion: comp, suggestedScore: sug, words: words)
    }
}

// MARK: - 映射到 app 现有的 ScoreResult(overall/perWord/weak),UI 不用改
extension SOEResult {
    func toScoreResult(target: SceneSentence, transcript: String) -> ScoreResult {
        let targetWords = target.words
        var perWord = [Double](repeating: 0, count: targetWords.count)
        // SOE 的 Words 按参考词顺序返回,逐位对齐目标词(准确度 0–100 → 0–1)
        for i in targetWords.indices where i < words.count {
            perWord[i] = min(1.0, max(0.0, words[i].accuracy / 100.0))
        }
        let weak = perWord.indices.filter { perWord[$0] < PronunciationScorer.weakThreshold }
        let recognizedText = words.map { $0.word }.joined(separator: " ")
        // 三维度带给反馈卡(流利/完整是 0–1,静音时可能 -1,clamp 到 0–100)
        let clamp = { (v: Double) -> Int in Int(min(100, max(0, v)).rounded()) }
        let detail = SOEDetail(
            accuracy: clamp(pronAccuracy),
            fluency: clamp(pronFluency * 100),
            completion: clamp(pronCompletion * 100),
            words: words.map { SOEWordDetail(word: $0.word, accuracy: $0.accuracy, phones: $0.phones) }
        )
        return ScoreResult(
            overall: Int(suggestedScore.rounded()),
            perWordScore: perWord,
            weakIndexes: Array(weak),
            recognized: recognizedText.isEmpty ? transcript : recognizedText,
            targetNormalized: targetWords,
            soe: detail
        )
    }
}
