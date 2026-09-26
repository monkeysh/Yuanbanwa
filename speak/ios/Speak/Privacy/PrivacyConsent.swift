import SwiftUI

// 隐私政策 / 用户协议:首次启动同意门与「我的」页入口共用的常量。
enum PrivacyConsent {
    /// 政策有实质变更时 +1,老用户会重新看到同意页。
    static let currentVersion = 1
    static let storageKey = "privacyConsent.version"
    static let termsURL = URL(string: "https://speak.yuanbanwa.top/terms.html")!
    static let privacyURL = URL(string: "https://speak.yuanbanwa.top/privacy.html")!

    static var appVersionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

// 首次启动的隐私同意页:说清楚数据去向,给出可点开的协议与政策链接。
// 未同意前不进入主界面,也不申请任何权限(国内监管与 App Store 审核都看这一点)。
struct PrivacyConsentScreen: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(PrivacyConsent.storageKey) private var consentVersion = 0
    @State private var showDeclineNote = false

    var body: some View {
        let p = theme.palette
        ZStack {
            p.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    card
                    buttons
                }
                .padding(.horizontal, 22)
                .padding(.top, 48)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [p.accent, p.accentDeep],
                                         center: UnitPoint(x: 0.3, y: 0.3),
                                         startRadius: 0, endRadius: 60))
                    .frame(width: 80, height: 80)
                Image(systemName: "mic.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("欢迎使用原版娃口语")
                .font(AppFont.zh(size: 26, weight: .semibold))
                .foregroundStyle(p.ink)
                .padding(.top, 6)
            Text("开始之前,请了解我们如何处理你的信息。")
                .font(AppFont.zh(size: 14))
                .foregroundStyle(p.inkSoft)
        }
    }

    private var card: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 14) {
            bullet("iphone", "练习进度、复练队列和学习数据只保存在这台设备上。没有账号,也不会上传。")
            bullet("waveform", "跟读评分时,你的录音会经我们的服务器发送给腾讯云口语评测服务打分;服务器不保存录音。")
            bullet("bubble.left.and.bubble.right", "模拟考官时,你回答的文字会经我们的服务器发送给 AI 服务生成问题和点评;不发送录音。")
            bullet("hand.raised", "只有你点击开始跟读时才会申请麦克风和语音识别权限。不做广告追踪,不做用户画像。")
            HStack(spacing: 14) {
                Link("《用户协议》", destination: PrivacyConsent.termsURL)
                Link("《隐私政策》", destination: PrivacyConsent.privacyURL)
            }
            .font(AppFont.zh(size: 14, weight: .semibold))
            .tint(p.accent)
            .padding(.top, 4)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(p.line, lineWidth: 1))
        )
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        let p = theme.palette
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(p.accent)
                .frame(width: 22)
            Text(text)
                .font(AppFont.zh(size: 14))
                .foregroundStyle(p.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var buttons: some View {
        let p = theme.palette
        return VStack(spacing: 12) {
            PrimaryButton(action: agree) {
                Text("同意并开始")
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
            }
            GhostButton(action: { withAnimation { showDeclineNote = true } }) {
                Text("暂不同意")
            }
            if showDeclineNote {
                Text("不同意隐私政策就无法使用练习功能。你可以先阅读上面两份文件,随时回来继续。")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkSoft)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(.top, 6)
    }

    private func agree() {
        Haptics.success()
        consentVersion = PrivacyConsent.currentVersion
    }
}
