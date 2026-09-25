import SwiftUI

// Two-step login: phone number → OTP. Mock auth accepts any 11-digit phone
// and any 4-digit code. Visual style matches the cream/dusk brand.

struct LoginScreen: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var auth: AuthManager

    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var step: Step = .phone
    @State private var errorMsg: String?
    @FocusState private var phoneFocused: Bool
    @FocusState private var codeFocused: Bool

    enum Step { case phone, code }

    var body: some View {
        let p = theme.palette
        ZStack {
            p.bg.ignoresSafeArea()
            backgroundGlow

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 48)
                        .padding(.bottom, 48)

                    card
                        .padding(.horizontal, 22)

                    footer
                        .padding(.top, 20)
                        .padding(.horizontal, 22)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Sections

    private var header: some View {
        let p = theme.palette
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [p.accent, p.accentDeep],
                                         center: UnitPoint(x: 0.3, y: 0.3),
                                         startRadius: 0, endRadius: 70))
                    .frame(width: 96, height: 96)
                    .shadow(color: p.accent.opacity(0.4), radius: 24, y: 12)
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("原版娃口语")
                .font(AppFont.zh(size: 26, weight: .semibold))
                .foregroundStyle(p.ink)
                .padding(.top, 6)
            Text("帮不敢开口的人，用最低门槛每天练会高频场景英语")
                .font(AppFont.zh(size: 13))
                .foregroundStyle(p.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var card: some View {
        let p = theme.palette
        let adminInput = AuthManager.isAdminInput(phone)
        return VStack(alignment: .leading, spacing: 16) {
            Text(cardTitle)
                .font(AppFont.zh(size: 17, weight: .semibold))
                .foregroundStyle(p.ink)

            if step == .phone {
                phoneField
                if adminInput {
                    PrimaryButton(action: adminLogin) {
                        Text("以超管 \(phone.trimmingCharacters(in: .whitespaces)) 身份登录")
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                    }
                } else {
                    PrimaryButton(action: sendCode) {
                        Text("获取验证码")
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                    }
                }
            } else {
                codeField
                PrimaryButton(action: submitCode) {
                    Text("登录")
                    Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                }
                resendRow
            }

            if let msg = errorMsg {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12))
                    Text(msg)
                }
                .font(AppFont.zh(size: 12))
                .foregroundStyle(p.danger)
                .transition(.opacity)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.surface)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(p.line, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.04), radius: 20, y: 8)
    }

    private var phoneField: some View {
        let p = theme.palette
        let adminInput = AuthManager.isAdminInput(phone)
        return VStack(alignment: .leading, spacing: 6) {
            if adminInput {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(p.accent)
                    Text("超管身份 · 免验证码")
                        .font(AppFont.zh(size: 11, weight: .semibold))
                        .foregroundStyle(p.accent)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            HStack(spacing: 10) {
                if !adminInput {
                    Text("+86")
                        .font(AppFont.enSans(size: 16, weight: .medium))
                        .foregroundStyle(p.inkSoft)
                        .padding(.trailing, 6)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(p.line).frame(width: 1, height: 22)
                        }
                }
                TextField(adminInput ? "超管 ID" : "请输入手机号", text: $phone)
                    .keyboardType(.numberPad)
                    .textContentType(adminInput ? .username : .telephoneNumber)
                    .font(AppFont.enSans(size: 16))
                    .foregroundStyle(p.ink)
                    .focused($phoneFocused)
                    .onChange(of: phone) { _, new in
                        // Cap at 11 digits (admin IDs are 3 digits so they
                        // still fit). Keep only digit characters so the
                        // admin detection and normal flow agree.
                        phone = String(new.filter(\.isNumber).prefix(11))
                        errorMsg = nil
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(p.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(adminInput ? p.accent.opacity(0.5) : .clear, lineWidth: 1.5)
            )
        }
        .onAppear { phoneFocused = true }
        .animation(.easeInOut(duration: 0.18), value: adminInput)
    }

    private var codeField: some View {
        let p = theme.palette
        return VStack(alignment: .leading, spacing: 8) {
            Text("验证码已发送至 +86 \(formattedPhone)")
                .font(AppFont.zh(size: 12))
                .foregroundStyle(p.inkSoft)
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    codeBox(index: i)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            // The real text field lives offscreen; the 4 visual boxes display it.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($codeFocused)
                .opacity(0.01)  // invisible but still receives keyboard input
                .frame(height: 1)
                .onChange(of: code) { _, new in
                    code = String(new.filter(\.isNumber).prefix(4))
                    errorMsg = nil
                    if code.count == 4 { submitCode() }
                }
        }
        .onTapGesture { codeFocused = true }
        .onAppear { codeFocused = true }
    }

    private func codeBox(index: Int) -> some View {
        let p = theme.palette
        let chars = Array(code)
        let ch: String = index < chars.count ? String(chars[index]) : ""
        let active = index == chars.count
        return Text(ch)
            .font(AppFont.enSans(size: 26, weight: .semibold))
            .foregroundStyle(p.ink)
            .frame(width: 54, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(p.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(active ? p.accent : p.line, lineWidth: active ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { codeFocused = true }
    }

    private var resendRow: some View {
        let p = theme.palette
        return HStack(spacing: 6) {
            if auth.codeCooldownSecs > 0 {
                Text("\(auth.codeCooldownSecs)s 后可重发")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkMuted)
            } else {
                Button {
                    Haptics.tap()
                    sendCode()
                } label: {
                    Text("重新发送验证码")
                        .font(AppFont.zh(size: 12, weight: .semibold))
                        .foregroundStyle(p.accent)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button {
                Haptics.tap()
                withAnimation(.easeOut(duration: 0.2)) {
                    step = .phone
                    code = ""
                    errorMsg = nil
                }
            } label: {
                Text("换个手机号")
                    .font(AppFont.zh(size: 12))
                    .foregroundStyle(p.inkSoft)
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        let p = theme.palette
        return VStack(spacing: 8) {
            Text("登录即代表同意 用户协议 · 隐私政策")
                .font(AppFont.zh(size: 11))
                .foregroundStyle(p.inkMuted)
            Text("首次使用任意 11 位手机号 + 任意 4 位数字即可进入 · 超管输入 001 / 218")
                .font(AppFont.zh(size: 11))
                .foregroundStyle(p.inkMuted.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
    }

    private var backgroundGlow: some View {
        let p = theme.palette
        return GeometryReader { geo in
            Circle()
                .fill(RadialGradient(colors: [p.accent.opacity(0.12), .clear],
                                     center: .center, startRadius: 0, endRadius: 260))
                .frame(width: 520, height: 520)
                .position(x: geo.size.width * 0.25, y: geo.size.height * 0.1)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private var cardTitle: String {
        if step == .code { return "输入验证码" }
        return AuthManager.isAdminInput(phone) ? "超管登录" : "输入手机号登录"
    }

    private func adminLogin() {
        errorMsg = nil
        switch auth.signInAsAdmin(phone) {
        case .success:
            Haptics.success()
            // RootView / AppGate swaps to main UI automatically.
        case .failure(let err):
            Haptics.warning()
            errorMsg = err.errorDescription
        }
    }

    private func sendCode() {
        errorMsg = nil
        switch auth.requestCode(phone: phone) {
        case .success:
            Haptics.success()
            withAnimation(.easeOut(duration: 0.25)) {
                step = .code
                code = "1234"   // 体验版不发真短信：自动填演示码（count==4 触发自动登录）
            }
        case .failure(let err):
            Haptics.warning()
            errorMsg = err.errorDescription
        }
    }

    private func submitCode() {
        errorMsg = nil
        switch auth.verifyCode(code) {
        case .success:
            Haptics.success()
            // RootView swaps to TabView on its own as soon as `auth.account`
            // becomes non-nil.
        case .failure(let err):
            Haptics.warning()
            errorMsg = err.errorDescription
        }
    }

    private var formattedPhone: String {
        let p = auth.pendingPhone ?? phone
        guard p.count == 11 else { return p }
        // 138 **** 1234 format
        let head = p.prefix(3)
        let tail = p.suffix(4)
        return "\(head) **** \(tail)"
    }
}
