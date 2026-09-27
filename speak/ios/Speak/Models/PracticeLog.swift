import Foundation

// 学习数据 S1:练习 session 明细落盘(docs/DESIGN-学习数据板块-2026-07-31.md)。
// SOE 音素级分数此前练完即丢;这里裁剪聚合后留存,为成长页/发音体检/家长周报供数。
// 存 Documents/practice_log.v1.json 单文件;封顶 1000 条且 365 天,超限最老的折进月度汇总。
//
// 口径铁律:
// ① 假分红线 — 只有真实 SOE 评分句进分数统计;词匹配/降级句只计 sentenceCount,
//    scoredCount==0 时所有 avg 为 nil,UI 必须显示"未评分",绝不编分。
// ② "天"一律设备本地日(yyyy-MM-dd),吸取主站 progress.ts UTC 事故。
// ③ 上线日起记,不回填不伪造历史;AppStore 旧聚合字段(streak 等)原样并存。
// ④ schemaVersion 门:文件版本比当前新(降级安装)→ 只当空数据,绝不写盘毁文件。

struct WeakWord: Codable, Equatable {
    let word: String
    let score: Int            // SOE 词准确度 0…100
}

// 音素聚合只存 sum/count(不存逐次明细),千条 session 仍 <2MB
struct PhoneStat: Codable, Equatable {
    let phone: String         // SOE 返回的音素标签,原样存;中文映射是 S3 的事
    var sumAcc: Double
    var count: Int
}

struct PracticeSession: Codable, Identifiable {
    let id: UUID
    let day: String           // "yyyy-MM-dd" 设备本地日
    let startedAt: Date
    let sceneId: String
    let tierLevel: String
    let mode: String          // "practice" | "review" | "drill" | "exam"
    let sentenceCount: Int    // 本次完成句数(含未评分句)
    let scoredCount: Int      // 真实 SOE 评分句数
    let avgOverall: Int?      // scoredCount==0 → nil(铁律①)
    let avgAccuracy: Int?
    let avgFluency: Int?
    let avgCompletion: Int?   // 自由说模式(考官)无此维度 → nil,不是 0
    let weakWords: [WeakWord]     // <65 分词,去重取最低,最多 20 条
    let phoneStats: [PhoneStat]   // session 内音素聚合(发音体检的原料)
    let durationSec: Int
    // mode=="exam" 时:sceneId 存英文 topic、tierLevel 存 KET/PET/FCE,此字段存中文话题供展示。
    // 可选字段:旧文件解出 nil、旧版 App 读新文件忽略未知键,双向兼容,无需升 schemaVersion。
    var examTopicZh: String? = nil
}

// 超限折叠的月度汇总:明细丢、聚合不丢(长期趋势 + 全期发音体检仍可算)
struct MonthRollup: Codable {
    var days: Set<String>         // 该月练过的本地日(一个月 ≤31 条,不膨胀)
    var sessionCount: Int
    var sentenceCount: Int
    var scoredCount: Int
    var sumOverallWeighted: Double   // Σ(avgOverall × scoredCount),月均分 = 此值/scoredCount
    var phoneStats: [PhoneStat]
}

struct PracticeLogFile: Codable {
    var schemaVersion: Int
    var sessions: [PracticeSession]
    var monthlyRollup: [String: MonthRollup]   // "2026-07" → 聚合

    static let empty = PracticeLogFile(schemaVersion: PracticeLogStore.schemaVersion,
                                       sessions: [], monthlyRollup: [:])
}

enum PracticeLogStore {
    static let schemaVersion = 1
    static let maxSessions = 1000
    static let maxAgeDays = 365

    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("practice_log.v1.json")
    }

    // 只解版本号的轻量探针 — 整文件 decode 之前先判版本,防止把"未来版本"误判为损坏
    private struct VersionProbe: Codable { let schemaVersion: Int }

    static func load() -> PracticeLogFile {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        if let probe = try? JSONDecoder().decode(VersionProbe.self, from: data),
           probe.schemaVersion > schemaVersion {
            // 降级安装读到新版文件:当空数据用,绝不写盘(铁律④)
            NSLog("[PracticeLog] 文件 schemaVersion=%d 高于当前 %d,只读跳过", probe.schemaVersion, schemaVersion)
            return .empty
        }
        if let file = try? JSONDecoder().decode(PracticeLogFile.self, from: data) {
            return file
        }
        // 版本 ≤ 当前但整体解不开 = 真损坏:挪走留证,重建空文件
        let corruptURL = fileURL.appendingPathExtension("corrupt")
        try? FileManager.default.removeItem(at: corruptURL)
        try? FileManager.default.moveItem(at: fileURL, to: corruptURL)
        NSLog("[PracticeLog] 文件损坏,已挪至 %@", corruptURL.lastPathComponent)
        return .empty
    }

    // 写串行化:防两个 session 几乎同时结束时 load-modify-save 竞态。
    // 读方不进此队列:save 用 .atomic(rename 语义),读永远拿到完整旧/新文件。
    private static let ioQueue = DispatchQueue(label: "com.yuanbanwa.speak.practice-log", qos: .utility)

    static func append(_ session: PracticeSession) {
        ioQueue.async { appendSync(session) }
    }

    private static func appendSync(_ session: PracticeSession) {
        // 降级安装场景:盘上是新版文件 → 不写(load 返回 empty 但盘上文件仍在,须再探一次)
        if let data = try? Data(contentsOf: fileURL),
           let probe = try? JSONDecoder().decode(VersionProbe.self, from: data),
           probe.schemaVersion > schemaVersion {
            NSLog("[PracticeLog] 新版文件在盘,跳过写入")
            return
        }
        var file = load()
        file.sessions.append(session)
        trim(&file)
        save(file)
    }

    // 封顶:超 1000 条或最老超 365 天 → 折进月度汇总
    private static func trim(_ file: inout PracticeLogFile) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let cutoff = Calendar.current.date(byAdding: .day, value: -maxAgeDays, to: Date())
            .map { fmt.string(from: $0) } ?? ""

        var keep: [PracticeSession] = []
        var fold: [PracticeSession] = []
        for s in file.sessions {
            if s.day < cutoff { fold.append(s) } else { keep.append(s) }
        }
        if keep.count > maxSessions {
            let overflow = keep.count - maxSessions
            fold.append(contentsOf: keep.prefix(overflow))
            keep.removeFirst(overflow)
        }
        for s in fold { rollup(s, into: &file.monthlyRollup) }
        file.sessions = keep
    }

    private static func rollup(_ s: PracticeSession, into map: inout [String: MonthRollup]) {
        let month = String(s.day.prefix(7))   // "yyyy-MM"
        var r = map[month] ?? MonthRollup(days: [], sessionCount: 0, sentenceCount: 0,
                                          scoredCount: 0, sumOverallWeighted: 0, phoneStats: [])
        r.days.insert(s.day)
        r.sessionCount += 1
        r.sentenceCount += s.sentenceCount
        r.scoredCount += s.scoredCount
        if let avg = s.avgOverall { r.sumOverallWeighted += Double(avg * s.scoredCount) }
        r.phoneStats = mergePhoneStats(r.phoneStats, s.phoneStats)
        map[month] = r
    }

    static func mergePhoneStats(_ a: [PhoneStat], _ b: [PhoneStat]) -> [PhoneStat] {
        var byPhone = Dictionary(a.map { ($0.phone, $0) }, uniquingKeysWith: { x, y in
            PhoneStat(phone: x.phone, sumAcc: x.sumAcc + y.sumAcc, count: x.count + y.count)
        })
        for p in b {
            if let existing = byPhone[p.phone] {
                byPhone[p.phone] = PhoneStat(phone: p.phone,
                                             sumAcc: existing.sumAcc + p.sumAcc,
                                             count: existing.count + p.count)
            } else {
                byPhone[p.phone] = p
            }
        }
        return byPhone.values.sorted { $0.phone < $1.phone }
    }

    private static func save(_ file: PracticeLogFile) {
        guard let data = try? JSONEncoder().encode(file) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - 从一次练习的逐句 SOE 结果构建 session(聚合逻辑收在这,AppStore 只薄透传)

extension PracticeSession {
    static let weakWordThreshold = 65.0

    /// scored: 每个真实评分句的 (overall, SOE 明细);未评分句不在其中(铁律①)
    static func build(sceneId: String, tierLevel: String, mode: String,
                      sentenceCount: Int, scored: [(overall: Int, soe: SOEDetail)],
                      startedAt: Date, durationSec: Int,
                      examTopicZh: String? = nil) -> PracticeSession {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current

        let n = scored.count
        // 负值 = 该维度本次不适用(腾讯自己就用 -1 表示,如自由说模式无完整度),
        // 剔除后再平均;全不适用则为 nil。绝不把「不适用」当 0 分算进平均(假分红线)。
        func avg(_ pick: (SOEDetail) -> Int) -> Int? {
            let vs = scored.map { pick($0.soe) }.filter { $0 >= 0 }
            return vs.isEmpty ? nil : Int((Double(vs.reduce(0, +)) / Double(vs.count)).rounded())
        }

        // 弱词:<65 分,同词去重取最低,升序取前 20
        var worst: [String: Int] = [:]
        for (_, soe) in scored {
            for w in soe.words where w.accuracy < weakWordThreshold {
                let sc = Int(w.accuracy.rounded())
                worst[w.word] = min(worst[w.word] ?? 101, sc)
            }
        }
        let weakWords = worst.map { WeakWord(word: $0.key, score: $0.value) }
            .sorted { $0.score < $1.score }
            .prefix(20)

        // 音素聚合:phone → sum/count(-1 等异常准确度剔除)
        var phones: [PhoneStat] = []
        for (_, soe) in scored {
            let stats = soe.words.flatMap { $0.phones }
                .filter { $0.accuracy >= 0 }
                .map { PhoneStat(phone: $0.phone, sumAcc: $0.accuracy, count: 1) }
            phones = PracticeLogStore.mergePhoneStats(phones, stats)
        }

        return PracticeSession(
            id: UUID(),
            day: fmt.string(from: startedAt),
            startedAt: startedAt,
            sceneId: sceneId,
            tierLevel: tierLevel,
            mode: mode,
            sentenceCount: sentenceCount,
            scoredCount: n,
            avgOverall: n == 0 ? nil : Int((Double(scored.map(\.overall).reduce(0, +)) / Double(n)).rounded()),
            avgAccuracy: avg { $0.accuracy },
            avgFluency: avg { $0.fluency },
            avgCompletion: avg { $0.completion },
            weakWords: Array(weakWords),
            phoneStats: phones,
            durationSec: durationSec,
            examTopicZh: examTopicZh
        )
    }
}

// MARK: - 成长页聚合(S2):本周速览/14天趋势/28天热力/考官记录,全部只基于真实数据

struct GrowthStats {
    var weekDays = 0              // 近 7 天练习天数
    var weekSentences = 0
    var weekAvg: Int? = nil       // 近 7 天平均 overall(按评分句数加权;无真分 → nil,绝不编分)
    var prevWeekAvg: Int? = nil   // 再前 7 天,给 ± 对比
    var daily14: [(day: String, avg: Int?, sentences: Int)] = []   // 旧→新,含今天
    var heat28: [Int] = []        // 28 格句数分级 0…3,旧→新,末位=今天
    var recentExams: [PracticeSession] = []   // mode=="exam",新→旧,最多 5 条
}

extension PracticeLogStore {
    static func growthStats(now: Date = Date()) -> GrowthStats {
        let file = load()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let cal = Calendar.current
        func dayStr(_ offset: Int) -> String {
            fmt.string(from: cal.date(byAdding: .day, value: -offset, to: now) ?? now)
        }
        // 按本地日分组(monthlyRollup 里只有月级聚合,近28天窗口内的明细都还在 sessions)
        var byDay: [String: (sentences: Int, scored: Int, weighted: Double)] = [:]
        for s in file.sessions {
            var d = byDay[s.day] ?? (0, 0, 0)
            d.sentences += s.sentenceCount
            if let avg = s.avgOverall {
                d.scored += s.scoredCount
                d.weighted += Double(avg * s.scoredCount)
            }
            byDay[s.day] = d
        }
        func rangeAvg(_ offsets: ClosedRange<Int>) -> Int? {
            var scored = 0; var weighted = 0.0
            for o in offsets { if let d = byDay[dayStr(o)] { scored += d.scored; weighted += d.weighted } }
            return scored == 0 ? nil : Int((weighted / Double(scored)).rounded())
        }
        var g = GrowthStats()
        for o in 0...6 {
            if let d = byDay[dayStr(o)], d.sentences > 0 {
                g.weekDays += 1
                g.weekSentences += d.sentences
            }
        }
        g.weekAvg = rangeAvg(0...6)
        g.prevWeekAvg = rangeAvg(7...13)
        for o in stride(from: 13, through: 0, by: -1) {
            let key = dayStr(o)
            let d = byDay[key]
            let scored = d?.scored ?? 0
            g.daily14.append((day: key,
                              avg: scored == 0 ? nil : Int(((d?.weighted ?? 0) / Double(scored)).rounded()),
                              sentences: d?.sentences ?? 0))
        }
        for o in stride(from: 27, through: 0, by: -1) {
            let n = byDay[dayStr(o)]?.sentences ?? 0
            g.heat28.append(n == 0 ? 0 : n <= 5 ? 1 : n <= 15 ? 2 : 3)
        }
        g.recentExams = file.sessions.filter { $0.mode == "exam" }
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(5).map { $0 }
        return g
    }
}
