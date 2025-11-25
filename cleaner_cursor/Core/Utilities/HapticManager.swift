import UIKit

// MARK: - Haptic Manager
/// Менеджер для управления тактильной обратной связью

enum HapticManager {
    
    // MARK: - Impact Feedback
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func lightImpact() {
        impact(.light)
    }
    
    static func mediumImpact() {
        impact(.medium)
    }
    
    static func heavyImpact() {
        impact(.heavy)
    }
    
    static func softImpact() {
        impact(.soft)
    }
    
    static func rigidImpact() {
        impact(.rigid)
    }
    
    // MARK: - Notification Feedback
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func success() {
        notification(.success)
    }
    
    static func warning() {
        notification(.warning)
    }
    
    static func error() {
        notification(.error)
    }
    
    // MARK: - Selection Feedback
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

