import UIKit

// Wraps UIFeedbackGenerator with pre-warmed instances. Call Haptics.tap()
// from button actions, Haptics.success() after a correct sentence, etc.

enum Haptics {
    static let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    static let softImpact   = UIImpactFeedbackGenerator(style: .soft)
    static let notification = UINotificationFeedbackGenerator()
    static let selection    = UISelectionFeedbackGenerator()

    static func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        notification.prepare()
        selection.prepare()
    }

    static func tap()       { lightImpact.impactOccurred() }
    static func press()     { mediumImpact.impactOccurred(intensity: 0.9) }
    static func soft()      { softImpact.impactOccurred() }
    static func select()    { selection.selectionChanged() }
    static func success()   { notification.notificationOccurred(.success) }
    static func warning()   { notification.notificationOccurred(.warning) }
    static func failure()   { notification.notificationOccurred(.error) }
}
