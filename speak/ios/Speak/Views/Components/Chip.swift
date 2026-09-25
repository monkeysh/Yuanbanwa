import SwiftUI

// Pill-shaped labels used across cards (level, duration, tags).
// Four tones match the web design: neutral / accent / sage / sun.

struct Chip: View {
    enum Tone { case neutral, accent, sage, sun }

    let text: String
    var tone: Tone = .neutral
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        let (bg, fg) = colors(for: p)
        return Text(text)
            .font(AppFont.zh(size: 11.5, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bg, in: .capsule)
            .foregroundStyle(fg)
    }

    private func colors(for p: Palette) -> (Color, Color) {
        switch tone {
        case .neutral: return (p.surfaceAlt, p.inkSoft)
        case .accent:  return (p.accentSoft, p.accentDeep)
        case .sage:    return (p.sageSoft, p.isDark ? p.sage : Color(red: 0.306, green: 0.416, blue: 0.290))
        case .sun:     return (p.sunSoft, p.isDark ? p.sun  : Color(red: 0.612, green: 0.478, blue: 0.122))
        }
    }
}
