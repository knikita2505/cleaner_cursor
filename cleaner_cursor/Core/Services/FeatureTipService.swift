import SwiftUI

// MARK: - Feature Tip Service
/// Сервис для управления показом подсказок при первом посещении функционала

@MainActor
final class FeatureTipService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FeatureTipService()
    
    // MARK: - Feature Keys
    
    enum Feature: String, CaseIterable {
        case cleanPhotos = "tip_clean_photos"
        case swipe = "tip_swipe"
        case secretSpace = "tip_secret_space"
        case contacts = "tip_contacts"
        case deviceHealth = "tip_device_health"
        case cleaningHistory = "tip_cleaning_history"
    }
    
    // MARK: - Private
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    func shouldShowTip(for feature: Feature) -> Bool {
        return !defaults.bool(forKey: feature.rawValue)
    }
    
    func markTipAsShown(for feature: Feature) {
        defaults.set(true, forKey: feature.rawValue)
    }
    
    func resetAllTips() {
        Feature.allCases.forEach { feature in
            defaults.removeObject(forKey: feature.rawValue)
        }
    }
}

// MARK: - Feature Tip Data

struct FeatureTipData {
    let title: String
    let pages: [FeatureTipPage]
}

struct FeatureTipPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Predefined Tips

extension FeatureTipData {
    
    // MARK: - Clean Photos Tip
    
    static let cleanPhotos = FeatureTipData(
        title: "Photo Cleaner",
        pages: [
            FeatureTipPage(
                icon: "square.on.square",
                title: "Duplicates",
                description: "Find and remove identical photos that take up extra space"
            ),
            FeatureTipPage(
                icon: "square.stack.3d.down.right",
                title: "Similar Photos",
                description: "Group similar shots and keep only the best ones"
            ),
            FeatureTipPage(
                icon: "camera.viewfinder",
                title: "Screenshots",
                description: "Clean up old screenshots you no longer need"
            ),
            FeatureTipPage(
                icon: "livephoto",
                title: "Live Photos",
                description: "Convert Live Photos to regular photos to save space"
            ),
            FeatureTipPage(
                icon: "video.fill",
                title: "Videos",
                description: "Find large videos and short clips to review"
            )
        ]
    )
    
    // MARK: - Swipe Tip
    
    static let swipe = FeatureTipData(
        title: "Swipe Photos",
        pages: [
            FeatureTipPage(
                icon: "hand.draw",
                title: "Swipe to Decide",
                description: "Swipe right to keep a photo, swipe left to delete"
            ),
            FeatureTipPage(
                icon: "calendar",
                title: "Organized by Month",
                description: "Photos are grouped by month for easy browsing"
            ),
            FeatureTipPage(
                icon: "checkmark.circle",
                title: "Review & Confirm",
                description: "All changes are applied only after you confirm"
            )
        ]
    )
    
    // MARK: - Secret Space Tip
    
    static let secretSpace = FeatureTipData(
        title: "Secret Space",
        pages: [
            FeatureTipPage(
                icon: "photo.on.rectangle.angled",
                title: "Hidden Album",
                description: "Store private photos and videos securely"
            ),
            FeatureTipPage(
                icon: "person.crop.circle.badge.checkmark",
                title: "Secret Contacts",
                description: "Keep sensitive contacts hidden from your address book"
            ),
            FeatureTipPage(
                icon: "lock.shield",
                title: "Protected Access",
                description: "Secure your data with passcode or Face ID"
            )
        ]
    )
    
    // MARK: - Contacts Tip
    
    static let contacts = FeatureTipData(
        title: "Contacts Cleaner",
        pages: [
            FeatureTipPage(
                icon: "person.2.fill",
                title: "Duplicates",
                description: "Find contacts with the same name, phone or email"
            ),
            FeatureTipPage(
                icon: "character.textbox",
                title: "Similar Names",
                description: "Detect names that differ by just 1-2 characters"
            ),
            FeatureTipPage(
                icon: "person.fill.questionmark",
                title: "Incomplete Contacts",
                description: "Find contacts missing name or phone number"
            ),
            FeatureTipPage(
                icon: "externaldrive.fill",
                title: "Backup & Restore",
                description: "Create backups before making any changes"
            )
        ]
    )
    
    // MARK: - Device Health Tip
    
    static let deviceHealth = FeatureTipData(
        title: "Device Health",
        pages: [
            FeatureTipPage(
                icon: "heart.fill",
                title: "Health Score",
                description: "See overall device condition at a glance"
            ),
            FeatureTipPage(
                icon: "internaldrive",
                title: "Storage Status",
                description: "Monitor available storage space"
            ),
            FeatureTipPage(
                icon: "battery.100",
                title: "Battery Insights",
                description: "Track battery level and charging status"
            ),
            FeatureTipPage(
                icon: "lightbulb.fill",
                title: "Smart Tips",
                description: "Get personalized recommendations to improve performance"
            )
        ]
    )
    
    // MARK: - Cleaning History Tip
    
    static let cleaningHistory = FeatureTipData(
        title: "Cleaning History",
        pages: [
            FeatureTipPage(
                icon: "chart.bar.fill",
                title: "Track Progress",
                description: "See how much space you've freed over time"
            ),
            FeatureTipPage(
                icon: "chart.pie.fill",
                title: "Category Breakdown",
                description: "View cleanup statistics by content type"
            ),
            FeatureTipPage(
                icon: "lightbulb.fill",
                title: "Recommendations",
                description: "Get suggestions based on your cleanup patterns"
            ),
            FeatureTipPage(
                icon: "trash.fill",
                title: "Clear History",
                description: "You can delete all history data anytime using the trash icon in the top right corner"
            )
        ]
    )
}
