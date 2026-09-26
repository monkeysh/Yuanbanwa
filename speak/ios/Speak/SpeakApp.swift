import SwiftUI

@main
struct SpeakApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(theme)
                .environmentObject(store)
                .preferredColorScheme(theme.preferredScheme)
                .tint(theme.palette.accent)
        }
    }
}

// 首次启动先展示隐私政策与用户协议,用户同意后才进入主界面;麦克风等权限只在练习时才申请。
// 这里不是登录门:App 没有账号体系,同意状态只存本机。
struct AppGate: View {
    @AppStorage(PrivacyConsent.storageKey) private var consentVersion = 0

    var body: some View {
        ZStack {
            if consentVersion >= PrivacyConsent.currentVersion {
                RootView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                PrivacyConsentScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: consentVersion)
    }
}
