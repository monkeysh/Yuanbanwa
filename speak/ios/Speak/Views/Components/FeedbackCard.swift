import SwiftUI

// Post-recording feedback surface. Shows the recognizer's similarity score,
// user vs demo waveform comparison, and a short coaching hint tied to the
// actual weak word (if any). All content driven by ScoreResult — no canned
// placeholders.

struct FeedbackCard: View {
    let target: SceneSentence
    let result: ScoreResult
    let userSamples: [Float]          // levels captured while recording
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        VStack(alignment: .leading, spacing: 12) {
            header
            if let soe = result.soe {
                soeDims(soe)
            } else {
                // 假波形(示范是合成的)只留给词匹配回落;SOE 真评分不配假装饰。
                VStack(spacing: 10) {
                    WaveformRow(label: "示范", samples: demoPattern(for: target),
                                color: p.inkMuted)
                    WaveformRow(label: "你的", samples: userSamples,
                                color: p.accent)
                }
            }
            if let soe = result.soe {
                soeWeakWords(soe)
            } else if !result.weakIndexes.isEmpty,
               let idx = result.weakIndexes.first,
               let word = target.words[safe: idx] {
                hint(for: word)
            } else if result.overall >= 90 {
                niceWork
            } else if result.recognized.isEmpty {
                noAudio
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(p.line, lineWidth: 1))
        )
    }

    private var header: some View {
        let p = theme.palette
        let verdict = verdictText
        return HStack(spacing: 8) {
            ZStack {
                Circle().fill(verdict.color.opacity(0.15)).frame(width: 22, height: 22)
                Image(systemName: verdict.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(verdict.color)
            }
            Text(verdict.label)
                .font(AppFont.zh(size: 14, weight: .semibold))
                .foregroundStyle(verdict.color)
            Spacer()
            Text(result.soe != nil ? "发音 \(result.overall) 分" : "识别 \(result.overall)%")
                .font(AppFont.zh(size: 11))
                .foregroundStyle(p.inkMuted)
        }
    }

    // ── SOE 真发音评测呈现:三维度 + 薄弱词音素 ──
    private func soeDims(_ soe: SOEDetail) -> some View {
        let p = theme.palette
        let dims: [(String, Int)] = [("准确度", soe.accuracy), ("流利度", soe.fluency), ("完整度", soe.completion)]
        return HStack(spacing: 8) {
            ForEach(dims, id: \.0) { d in
                VStack(spacing: 2) {
                    Text("\(d.1)")
                        .font(AppFont.enSerif(size: 18))
                        .foregroundStyle(p.ink)
                    Text(d.0)
                        .font(AppFont.zh(size: 10))
                        .foregroundStyle(p.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.surfaceAlt))
            }
        }
    }

    private func soeWeakWords(_ soe: SOEDetail) -> some View {
        let p = theme.palette
        let weak = soe.words
            .filter { $0.accuracy < 85 }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(3)
        return Group {
            if weak.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(p.sage)
                    Text("每个词的发音都到位，非常棒")
                        .font(AppFont.zh(size: 12.5))
                        .foregroundStyle(p.sage)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.sageSoft))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("这几个词的发音再练练")
                        .font(AppFont.zh(size: 12, weight: .semibold))
                        .foregroundStyle(p.accentDeep)
                    ForEach(Array(weak.enumerated()), id: \.offset) { _, w in
                        let badPhones = w.phones.filter { $0.accuracy < 70 }.prefix(3)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(w.word)
                                .font(AppFont.enSerif(size: 15))
                                .foregroundStyle(p.ink)
                            Text("\(Int(w.accuracy.rounded())) 分")
                                .font(AppFont.zh(size: 11))
                                .foregroundStyle(p.inkMuted)
                            if !badPhones.isEmpty {
                                Text("薄弱音素 " + badPhones.map { $0.phone }.joined(separator: " · "))
                                    .font(AppFont.zh(size: 11))
                                    .foregroundStyle(p.inkMuted)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.accentSoft))
            }
        }
    }

    private func hint(for word: String) -> some View {
        let p = theme.palette
        return HStack(alignment: .top, spacing: 6) {
            Text("\"\(word)\"")
                .font(AppFont.zh(size: 12.5, weight: .semibold))
                .foregroundStyle(p.accentDeep)
            Text("再慢一点试试 — 重音放在这个词上会更自然")
                .font(AppFont.zh(size: 12.5))
                .foregroundStyle(p.accentDeep)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.accentSoft)
        )
    }

    private var niceWork: some View {
        let p = theme.palette
        return HStack(spacing: 6) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 12))
                .foregroundStyle(p.sage)
            Text("这句很自然，明天再来一遍就更稳了")
                .font(AppFont.zh(size: 12.5))
                .foregroundStyle(p.sage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.sageSoft)
        )
    }

    private var noAudio: some View {
        let p = theme.palette
        return Text("没听清楚，再来一次 — 让手机离嘴近一点")
            .font(AppFont.zh(size: 12.5))
            .foregroundStyle(p.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.surfaceAlt)
            )
    }

    private var verdictText: (label: String, icon: String, color: Color) {
        let p = theme.palette
        switch result.overall {
        case 90...:      return ("很自然", "checkmark", p.sage)
        case 70..<90:    return ("很接近了", "checkmark", p.sage)
        case 50..<70:    return ("再来一次", "arrow.clockwise", p.accent)
        default:         return ("没听清楚", "exclamationmark", p.inkMuted)
        }
    }

    // Synthetic "demo" waveform derived stably from the target sentence —
    // word count sets the shape, so two different sentences don't look identical.
    // Swap this for real demo-audio envelopes in P2.
    private func demoPattern(for target: SceneSentence) -> [Float] {
        let seed = target.words.count
        return (0..<20).map { i in
            let base = 0.5 + 0.3 * sin(Double(i + seed) * 0.85)
            return Float(max(0.2, min(1, base)))
        }
    }
}
