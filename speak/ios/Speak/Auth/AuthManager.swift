import Foundation
import SwiftUI

// Single source of truth for login state. For v0 we persist the
// auth token to UserDefaults — switch to Keychain when we wire up a
// real backend + refresh tokens. Mock auth accepts any 11-digit phone
// and any 4-digit code. Super-admin accounts ("001", "218") bypass OTP.

// Super-admin identifiers — users type "001" or "218" in the phone field
// to bypass OTP. Must stay in sync with the web apps' ADMIN_IDS.
let ADMIN_IDS: Set<String> = ["001", "218"]

@MainActor
final class AuthManager: ObservableObject {

    enum Provider: String, Codable {
        case phone
        case admin
    }

    struct Account: Codable, Equatable {
        var phone: String
        var token: String         // Mock token for now; swap to JWT later.
        var signedInAt: Date
        var nickname: String
        var provider: Provider
        var adminId: String?      // Set only when provider == .admin
    }

    @Published private(set) var account: Account?
    @Published private(set) var pendingPhone: String?      // Set while OTP is expected.
    @Published private(set) var codeCooldownSecs: Int = 0  // 60 → 0 after requesting a code.

    private var cooldownTimer: Timer?
    private let storageKey = "authAccount.v1"

    var isSignedIn: Bool { account != nil }
    var isAdmin: Bool { account?.provider == .admin }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Account.self, from: data) {
            self.account = decoded
        }
    }

    // Whether the typed string is a super-admin identifier. Used by the
    // LoginScreen to swap its UI (hide OTP, change CTA label).
    static func isAdminInput(_ raw: String) -> Bool {
        ADMIN_IDS.contains(raw.trimmingCharacters(in: .whitespaces))
    }

    // Direct-login path for super admins. Returns .invalidPhone if the
    // input isn't one of the known admin IDs.
    func signInAsAdmin(_ rawId: String) -> Result<Void, AuthError> {
        let id = rawId.trimmingCharacters(in: .whitespaces)
        guard ADMIN_IDS.contains(id) else { return .failure(.invalidPhone) }
        let account = Account(
            phone: "",
            token: "admin-\(id)-\(UUID().uuidString)",
            signedInAt: Date(),
            nickname: "超管 \(id)",
            provider: .admin,
            adminId: id
        )
        self.account = account
        pendingPhone = nil
        stopCooldown()
        persist()
        return .success(())
    }

    // Step 1 — user entered phone, tapped "获取验证码".
    // Mock: any 11-digit number passes. Starts a 60-second cooldown.
    func requestCode(phone: String) -> Result<Void, AuthError> {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return .failure(.invalidPhone) }
        pendingPhone = digits
        startCooldown(seconds: 60)
        return .success(())
    }

    // Step 2 — user entered 4-digit code.
    // Mock: any 4 digits pass. Real backend will verify; on failure this
    // returns .failure(.wrongCode).
    func verifyCode(_ code: String) -> Result<Void, AuthError> {
        let digits = code.filter(\.isNumber)
        guard digits.count == 4 else { return .failure(.invalidCode) }
        guard let phone = pendingPhone else { return .failure(.noPhoneSet) }

        let account = Account(
            phone: phone,
            token: "mock-\(UUID().uuidString)",
            signedInAt: Date(),
            nickname: nicknameFor(phone: phone),
            provider: .phone,
            adminId: nil
        )
        self.account = account
        pendingPhone = nil
        stopCooldown()
        persist()
        return .success(())
    }

    func signOut() {
        account = nil
        pendingPhone = nil
        stopCooldown()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Internals

    private func persist() {
        guard let account else { return }
        if let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func nicknameFor(phone: String) -> String {
        // "138****1234" → show last 4 digits only. Private-ish but
        // recognisable so the user sees something personal.
        let tail = phone.suffix(4)
        return "学员\(tail)"
    }

    private func startCooldown(seconds: Int) {
        stopCooldown()
        codeCooldownSecs = seconds
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.codeCooldownSecs > 0 {
                    self.codeCooldownSecs -= 1
                } else {
                    self.stopCooldown()
                }
            }
        }
    }

    private func stopCooldown() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        codeCooldownSecs = 0
    }
}

enum AuthError: LocalizedError {
    case invalidPhone
    case invalidCode
    case noPhoneSet
    case wrongCode

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入 11 位手机号"
        case .invalidCode:  return "请输入 4 位验证码"
        case .noPhoneSet:   return "请先获取验证码"
        case .wrongCode:    return "验证码错误，请重新输入"
        }
    }
}
