//
//  TencentSOE.swift
//  腾讯云口语评测(SOE 新版)客户端 —— 把录音 WAV + 目标句送评测,拿回真发音分。
//  录音文件由 SpeechRecorder 产出(16kHz 单声道 PCM WAV),直接喂 FileDataSource。
//  MVP 凭据内嵌(SOESecrets,已 gitignore);正式版移后端签发临时 token。
//

import Foundation

/// SOE 整句评测结果(解析自 onResult 的 JSON)
struct SOEResult {
    let pronAccuracy: Double    // 发音准确度 0–100
    let pronFluency: Double     // 流利度 0–1
    let pronCompletion: Double  // 完整度 0–1
    let suggestedScore: Double  // 综合建议分 0–100
    let words: [SOEWord]
}

struct SOEWord {
    let word: String
    let accuracy: Double        // 0–100
    let matchTag: Int           // 0 匹配 / 1 多词 / 2 漏读 / 3 回读 / 4 替换（以官方为准）
    let phones: [SOEPhoneDetail] // 音素级得分(PhoneInfos),英文引擎才有
}

enum SOEError: LocalizedError {
    case noResult
    case failed(String)
    var errorDescription: String? {
        switch self {
        case .noResult: return "评测无结果"
        case .failed(let m): return m
        }
    }
}

/// 一次评测一个实例;`TencentSOE.evaluate` 内部 new 一个,评完即弃。
final class TencentSOE: NSObject, TAIOralListener {

    private var controller: TAIOralController?
    private var continuation: CheckedContinuation<SOEResult, Error>?
    private var resultJSON: String?
    private let lock = NSLock()

    /// 评测口径。
    /// - sentence:跟读用。有明确目标句,完整度(说全了没有)是有效的惩罚维度。
    /// - freeSpeak:开放式作答(模拟考官)用。学生的话没有标准答案,
    ///   此前把「语音识别转写的学生自己的话」当参考文本送评 —— 等于拿他说的话
    ///   当标准答案量他自己,完整度恒为满分、分数虚高(用户验收实测:答得又短又差
    ///   照样高分)。自由说模式不吃参考文本,只评发音本身,才是正确口径。
    enum Mode {
        case sentence
        case freeSpeak
        var apiValue: String { self == .freeSpeak ? "3" : "1" }
    }

    /// 对外入口:传录音 WAV 文件 + 目标英文句,异步返回真分。
    static func evaluate(wavURL: URL, refText: String, mode: Mode = .sentence) async throws -> SOEResult {
        let client = TencentSOE()
        return try await client.run(wavURL: wavURL, refText: refText, mode: mode)
    }

    private func run(wavURL: URL, refText: String, mode: Mode) async throws -> SOEResult {
        try await withCheckedThrowingContinuation { cont in
            lock.lock(); continuation = cont; resultJSON = nil; lock.unlock()

            let config = TAIOralConfig()
            config.appID = SOESecrets.appID
            config.secretID = SOESecrets.secretID
            config.secretKey = SOESecrets.secretKey
            config.token = SOESecrets.token
            config.setApiParam(kTAIVoiceFormat, value: "1")            // 1 = WAV
            config.setApiParam(kTAIServerEngineType, value: "16k_en")  // 英文 16k
            config.setApiParam(kTAIEvalMode, value: mode.apiValue)     // 1=句子 / 3=自由说
            config.setApiParam(kTAIRefText, value: refText)
            // 严格度 1.0(最宽松,儿童档)会把含糊快读也判 94 分 —— 实测 coeff 与
            // 分数的关系:含糊快读 1.0→94.4 / 2.0→92.5 / 3.0→88.4 / 4.0→73.5,
            // 而正常朗读 3.0 仍有 96.9。取 3.0:拉开好坏差距,又不误伤读得好的学生。
            config.setApiParam(kTAIScoreCoeff, value: "3.0")
            config.setApiParam(kTAIRecMode, value: "1")                // 一句话
            config.connectTimeout = 6000

            let source = FileDataSource(wavURL.path)
            controller = config.build(source, listener: self)
        }
    }

    private func finish(_ result: Result<SOEResult, Error>) {
        lock.lock()
        let cont = continuation; continuation = nil
        lock.unlock()
        controller = nil
        guard let cont else { return }
        switch result {
        case .success(let r): cont.resume(returning: r)
        case .failure(let e): cont.resume(throwing: e)
        }
    }

    // MARK: - TAIOralListener
    func onResult(_ result: String) {
        lock.lock(); resultJSON = result; lock.unlock()
        NSLog("[SOE] onResult raw = %@", result)   // 首跑用来核对字段名
    }

    func onFinish() {
        lock.lock(); let json = resultJSON; lock.unlock()
        if let json, let parsed = TencentSOE.parse(json) {
            finish(.success(parsed))
        } else {
            finish(.failure(SOEError.noResult))
        }
    }

    func onError(_ error: Error) {
        NSLog("[SOE] onError = %@", error.localizedDescription)
        finish(.failure(SOEError.failed(error.localizedDescription)))
    }

    // MARK: - 解析
    static func parse(_ json: String) -> SOEResult? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // 真实分数包在 result 对象里:{"code":0,"result":{"SuggestedScore":..,"Words":[..]}}
        let obj = (root["result"] as? [String: Any]) ?? root
        func num(_ dict: [String: Any], _ keys: [String]) -> Double {
            for k in keys { if let n = dict[k] as? NSNumber { return n.doubleValue } }
            return 0
        }
        let acc = num(obj, ["PronAccuracy", "pron_accuracy"])
        let flu = num(obj, ["PronFluency", "pron_fluency"])
        let comp = num(obj, ["PronCompletion", "pron_completion"])
        var sug = num(obj, ["SuggestedScore", "suggested_score"])
        if sug == 0 { sug = acc }
        var words: [SOEWord] = []
        if let arr = (obj["Words"] as? [[String: Any]]) ?? (obj["words"] as? [[String: Any]]) {
            for w in arr {
                let word = (w["Word"] as? String) ?? (w["word"] as? String) ?? ""
                let wacc = num(w, ["PronAccuracy", "pron_accuracy"])
                let tag = Int(num(w, ["MatchTag", "match_tag"]))
                // 音素级(PhoneInfos/PhoneInfo 两种字段名都见过,发音不准时给具体到音的提示)
                var phones: [SOEPhoneDetail] = []
                if let parr = (w["PhoneInfos"] as? [[String: Any]]) ?? (w["PhoneInfo"] as? [[String: Any]]) {
                    for p in parr {
                        let ph = (p["Phone"] as? String) ?? (p["phone"] as? String) ?? ""
                        guard !ph.isEmpty else { continue }
                        phones.append(SOEPhoneDetail(phone: ph, accuracy: num(p, ["PronAccuracy", "pron_accuracy"])))
                    }
                }
                words.append(SOEWord(word: word, accuracy: wacc, matchTag: tag, phones: phones))
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

// MARK: - 免麦自测(仅验证用,验完删)
enum SOESelfTest {
    static func run() async {
        guard let url = Bundle.main.url(forResource: "soe_test", withExtension: "wav") else {
            NSLog("[SOE-TEST] soe_test.wav 不在 bundle 里"); return
        }
        NSLog("[SOE-TEST] 开始, wav=%@", url.path)
        do {
            let r = try await TencentSOE.evaluate(wavURL: url, refText: "Hi! Nice to meet you. I'm Tom.")
            NSLog("[SOE-TEST] ✅ 准确度=%.1f 流利=%.2f 完整=%.2f 综合=%.1f 词数=%d",
                  r.pronAccuracy, r.pronFluency, r.pronCompletion, r.suggestedScore, r.words.count)
            for w in r.words { NSLog("[SOE-TEST]   词=%@ 准确=%.1f tag=%d", w.word, w.accuracy, w.matchTag) }
        } catch {
            NSLog("[SOE-TEST] ❌ 失败: %@", error.localizedDescription)
        }
    }
}
