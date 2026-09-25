import SwiftUI

@main
struct SpeakApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store = AppStore()
    @StateObject private var auth  = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(theme)
                .environmentObject(store)
                .environmentObject(auth)
                .preferredColorScheme(theme.preferredScheme)
                .tint(theme.palette.accent)
        }
    }
}

// Gates the entire UI on auth: if signed out, only LoginScreen is reachable.
// Signed-in → the usual TabView stack. Switching between the two animates
// cleanly so the transition feels intentional, not a screen flash.
struct AppGate: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            if auth.isSignedIn {
                RootView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                LoginScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
    }
}
