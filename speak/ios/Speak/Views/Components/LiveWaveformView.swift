import SwiftUI

// Renders a rolling waveform from a [Float] of normalized audio levels (0…1).
// Used in two places:
//   - Around the mic button while recording (symmetric radial bars)
//   - Inside the feedback card after stop (horizontal bars, for comparison)

struct LiveWaveformRing: View {
    let samples: [Float]          // rolling buffer; the last values are the most recent
    let color: Color
    var barCount: Int = 36
    var innerRadius: CGFloat = 60
    var maxLen: CGFloat = 22

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Downsample / replicate `samples` to exactly `barCount` values.
            let bars = resampled(samples, to: barCount)
            for i in 0..<barCount {
                let angle = (Double(i) / Double(barCount)) * 2 * .pi - .pi / 2
                let level = CGFloat(bars[i])
                let len = innerRadius + 3 + level * maxLen
                let x1 = center.x + innerRadius * CGFloat(cos(angle))
                let y1 = center.y + innerRadius * CGFloat(sin(angle))
                let x2 = center.x + len * CGFloat(cos(angle))
                let y2 = center.y + len * CGFloat(sin(angle))
                var path = Path()
                path.move(to: CGPoint(x: x1, y: y1))
                path.addLine(to: CGPoint(x: x2, y: y2))
                ctx.stroke(path, with: .color(color.opacity(0.55 + Double(level) * 0.45)),
                           style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
    }

    private func resampled(_ source: [Float], to n: Int) -> [Float] {
        if source.isEmpty { return Array(repeating: 0, count: n) }
        if source.count == n { return source }
        var out: [Float] = []
        out.reserveCapacity(n)
        let stride = Double(source.count) / Double(n)
        for i in 0..<n {
            let idx = min(source.count - 1, Int(Double(i) * stride))
            out.append(source[idx])
        }
        return out
    }
}

// Horizontal waveform row used in the feedback comparison card.
struct WaveformRow: View {
    let label: String
    let samples: [Float]            // 0…1
    let color: Color
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        HStack(spacing: 10) {
            Text(label)
                .font(AppFont.zh(size: 10))
                .foregroundStyle(p.inkMuted)
                .frame(width: 24)
            GeometryReader { geo in
                let bars = resampled(samples, to: 20)
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<bars.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(color.opacity(0.85))
                            .frame(width: max(2, (geo.size.width - Double(bars.count - 1) * 2) / Double(bars.count)),
                                   height: max(3, CGFloat(bars[i]) * geo.size.height))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)
        }
    }

    private func resampled(_ source: [Float], to n: Int) -> [Float] {
        if source.isEmpty {
            // Deterministic-looking placeholder so an empty row isn't blank.
            return (0..<n).map { Float(0.3 + 0.25 * sin(Double($0) * 0.9)) }
        }
        if source.count == n { return source.map { max(0.15, $0) } }
        var out: [Float] = []
        out.reserveCapacity(n)
        let stride = Double(source.count) / Double(n)
        for i in 0..<n {
            let idx = min(source.count - 1, Int(Double(i) * stride))
            out.append(max(0.15, source[idx]))
        }
        return out
    }
}
