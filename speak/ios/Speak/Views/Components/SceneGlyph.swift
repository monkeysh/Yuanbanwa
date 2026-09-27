import SwiftUI

// Abstract geometric glyphs for each scene category. Deliberately
// NOT illustrative — we want a calm product feel, not a cartoon.

struct SceneGlyph: View {
    let kind: String
    var size: CGFloat = 56
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        let colors = glyphColors(for: kind, in: p)
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(colors.bg)
            .frame(width: size, height: size)
            .overlay {
                ZStack {
                    shape(for: kind, fg: colors.fg, bg: colors.bg)
                }
                .frame(width: size, height: size)
            }
    }

    @ViewBuilder
    private func shape(for kind: String, fg: Color, bg: Color) -> some View {
        let s = size
        switch kind {
        case "travel":
            ZStack {
                Circle().fill(fg).frame(width: s * 10/28, height: s * 10/28)
                    .offset(x: -s * 6/28, y: s * 0/28)
                RoundedRectangle(cornerRadius: s * 4/28, style: .continuous)
                    .fill(fg.opacity(0.5))
                    .frame(width: s * 8/28, height: s * 8/28)
                    .offset(x: s * 4/28, y: -s * 0/28)
            }
        case "life":
            ZStack {
                RoundedRectangle(cornerRadius: s * 6/28, style: .continuous)
                    .fill(fg.opacity(0.4))
                    .frame(width: s * 16/28, height: s * 14/28)
                    .offset(y: -s * 0/28)
                Circle().fill(fg).frame(width: s * 7/28, height: s * 7/28)
                    .offset(y: s * 0/28)
            }
        case "school":
            ZStack {
                Diamond()
                    .fill(fg)
                    .frame(width: s * 18/28, height: s * 10/28)
                    .offset(y: -s * 4/28)
                Smile()
                    .stroke(fg, lineWidth: 2.5)
                    .frame(width: s * 10/28, height: s * 7/28)
                    .offset(y: s * 4/28)
            }
        case "social":
            ZStack {
                Circle().fill(fg).frame(width: s * 9/28, height: s * 9/28)
                    .offset(x: -s * 3/28, y: -s * 2/28)
                Circle().fill(fg.opacity(0.5)).frame(width: s * 7/28, height: s * 7/28)
                    .offset(x: s * 4/28, y: s * 2/28)
            }
        case "urgent":
            Triangle()
                .fill(fg)
                .frame(width: s * 16/28, height: s * 15/28)
                .overlay(
                    VStack(spacing: s * 1/28) {
                        Capsule().fill(bg).frame(width: s * 2/28, height: s * 5/28)
                        Circle().fill(bg).frame(width: s * 2/28, height: s * 2/28)
                    }
                    .offset(y: s * 3/28)
                )
        default:
            Circle().fill(fg).frame(width: s * 10/28, height: s * 10/28)
        }
    }

    private func glyphColors(for kind: String, in p: Palette) -> (bg: Color, fg: Color) {
        switch kind {
        case "travel": return (p.accentSoft, p.accent)
        case "life":   return (p.sageSoft, p.sage)
        case "school": return (p.sunSoft, p.isDark ? p.sun : Color(red: 0.761, green: 0.573, blue: 0.204))
        case "social":
            return p.isDark
                ? (Color(red: 0.627, green: 0.471, blue: 0.863).opacity(0.18),
                   Color(red: 0.710, green: 0.604, blue: 0.902))
                : (Color(red: 0.910, green: 0.871, blue: 0.965),
                   Color(red: 0.490, green: 0.353, blue: 0.710))
        case "urgent":
            return p.isDark
                ? (Color(red: 0.878, green: 0.502, blue: 0.439).opacity(0.18), p.danger)
                : (Color(red: 0.969, green: 0.863, blue: 0.831), p.danger)
        default: return (p.accentSoft, p.accent)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                           control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        }
    }
}
