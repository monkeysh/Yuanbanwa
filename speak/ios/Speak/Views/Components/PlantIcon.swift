import SwiftUI

// A plant that grows with consecutive-day streak — the same visual
// metaphor from the web design. 0 days = empty pot, 14+ = flower.

struct PlantIcon: View {
    let day: Int
    var size: CGFloat = 24
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        let level = levelFor(day: day)
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            // Pot
            let potPath = Path { p in
                p.move(to: CGPoint(x: w * 6/24, y: h * 17/24))
                p.addLine(to: CGPoint(x: w * 18/24, y: h * 17/24))
                p.addLine(to: CGPoint(x: w * 17/24, y: h * 22/24))
                p.addLine(to: CGPoint(x: w * 7/24, y: h * 22/24))
                p.closeSubpath()
            }
            ctx.fill(potPath, with: .color(p.potFill))
            ctx.stroke(potPath, with: .color(p.accentDeep), lineWidth: 1)
            // Soil
            let soil = Path(CGRect(x: w * 6/24, y: h * 16/24, width: w * 12/24, height: h * 2/24))
            ctx.fill(soil, with: .color(p.accentDeep.opacity(0.5)))

            // Stem
            if level >= 0 {
                let stemHeight = CGFloat(level + 1) * (h * 2.5/24)
                let stemPath = Path { p in
                    p.move(to: CGPoint(x: w * 12/24, y: h * 16/24))
                    p.addLine(to: CGPoint(x: w * 12/24, y: h * 16/24 - stemHeight))
                }
                ctx.stroke(stemPath, with: .color(p.sage), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            // Leaves — scaled-down ellipses rotated at the stem
            if level >= 1 {
                leafEllipse(ctx: ctx, center: CGPoint(x: w * 9.5/24, y: h * 13/24),
                            rx: w * 2/24, ry: h * 1.2/24, rotation: -30, color: p.sage)
                leafEllipse(ctx: ctx, center: CGPoint(x: w * 14.5/24, y: h * 11/24),
                            rx: w * 2/24, ry: h * 1.2/24, rotation: 30, color: p.sage)
            }
            if level >= 2 {
                leafEllipse(ctx: ctx, center: CGPoint(x: w * 9/24, y: h * 9/24),
                            rx: w * 2.3/24, ry: h * 1.3/24, rotation: -30, color: p.sage)
                leafEllipse(ctx: ctx, center: CGPoint(x: w * 15/24, y: h * 7/24),
                            rx: w * 2.3/24, ry: h * 1.3/24, rotation: 30, color: p.sage)
            }
            // Flower
            if level >= 3 {
                let flower = Path(ellipseIn: CGRect(x: w * 10/24, y: h * 3/24,
                                                     width: w * 4/24, height: h * 4/24))
                ctx.fill(flower, with: .color(p.accent))
                let core = Path(ellipseIn: CGRect(x: w * 11.2/24, y: h * 4.2/24,
                                                   width: w * 1.6/24, height: h * 1.6/24))
                ctx.fill(core, with: .color(p.sun))
            }
        }
        .frame(width: size, height: size)
    }

    private func leafEllipse(ctx: GraphicsContext, center: CGPoint,
                             rx: CGFloat, ry: CGFloat, rotation: CGFloat, color: Color) {
        var ctx = ctx
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: Angle(degrees: rotation))
        let rect = CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func levelFor(day: Int) -> Int {
        switch day {
        case ..<3:  return 0
        case 3..<7: return 1
        case 7..<14: return 2
        default:     return 3
        }
    }
}
