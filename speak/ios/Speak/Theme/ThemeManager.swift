import SwiftUI

// Cream by default; user can toggle to Dusk. We also offer a third
// "system" mode that follows iOS light/dark — useful once we're on
// TestFlight and users expect it.

@MainActor
final class ThemeManager: ObservableObject {
    enum Mode: String, CaseIterable {
        case cream, dusk, system
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "themeMode") }
    }
    @Published var systemScheme: ColorScheme = .light

    init() {
        let saved = UserDefaults.standard.string(forKey: "themeMode") ?? Mode.cream.rawValue
        self.mode = Mode(rawValue: saved) ?? .cream
    }

    var palette: Palette {
        switch mode {
        case .cream:  return .cream
        case .dusk:   return .dusk
        case .system: return systemScheme == .dark ? .dusk : .cream
        }
    }

    // Drives .preferredColorScheme so system chrome (status bar tint,
    // alert sheets) matches the palette instead of being cream-tinted
    // while the rest of the app is in dusk.
    var preferredScheme: ColorScheme? {
        switch mode {
        case .cream:  return .light
        case .dusk:   return .dark
        case .system: return nil
        }
    }
}
