import SwiftUI

// Primary (filled orange) and Ghost (outlined) buttons used across the app.
// Both support a pressed scale animation and a haptic tap.

struct PrimaryButton<Label: View>: View {
    let action: () -> Void
    var isBlock: Bool = true
    var isCompact: Bool = false
    @ViewBuilder let label: () -> Label
    @EnvironmentObject var theme: ThemeManager
    @State private var pressed = false

    var body: some View {
        let p = theme.palette
        Button {
            Haptics.press()
            action()
        } label: {
            HStack(spacing: 8) {
                label()
            }
            .font(AppFont.zh(size: isCompact ? 15 : 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: isBlock ? .infinity : nil)
            .padding(.vertical, isCompact ? 12 : 17)
            .padding(.horizontal, 22)
            .background(
                Capsule()
                    .fill(p.accent)
                    .shadow(color: p.accent.opacity(0.25), radius: 20, y: 8)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .mask(Capsule().frame(height: 1).offset(y: -21))
            )
            .scaleEffect(pressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .pressAction(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

struct GhostButton<Label: View>: View {
    let action: () -> Void
    var isBlock: Bool = true
    @ViewBuilder let label: () -> Label
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let p = theme.palette
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) { label() }
                .font(AppFont.zh(size: 15, weight: .medium))
                .foregroundStyle(p.ink)
                .frame(maxWidth: isBlock ? .infinity : nil)
                .padding(.vertical, 13)
                .padding(.horizontal, 18)
                .background(
                    Capsule().stroke(p.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Custom press tracking (SwiftUI's Button gives us no press state hook).
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
