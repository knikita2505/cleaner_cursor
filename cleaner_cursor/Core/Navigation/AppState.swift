import SwiftUI

// MARK: - App State
/// Глобальное состояние приложения

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Показывать ли онбординг
    @Published var showOnboarding: Bool = true
    
    /// Текущий таб
    @Published var selectedTab: AppTab = .dashboard
    
    /// Показывать ли paywall
    @Published var showPaywall: Bool = false
    
    /// Paywall вариант (A/B тестирование)
    @Published var paywallVariant: PaywallVariant = .a
    
    /// Навигационный путь для dashboard
    @Published var dashboardPath = NavigationPath()
    
    /// Навигационный путь для photos
    @Published var photosPath = NavigationPath()
    
    /// Показывать ли модальное окно разрешений
    @Published var showPermissionModal: Bool = false
    @Published var currentPermissionType: PermissionType?
    
    // MARK: - Singleton
    
    static let shared = AppState()
    
    // MARK: - Init
    
    private init() {
        loadState()
    }
    
    // MARK: - State Persistence
    
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    private func loadState() {
        showOnboarding = !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        
        // Determine paywall variant (simple A/B)
        if UserDefaults.standard.object(forKey: "paywallVariant") == nil {
            paywallVariant = Bool.random() ? .a : .b
            UserDefaults.standard.set(paywallVariant.rawValue, forKey: "paywallVariant")
        } else {
            let variantString = UserDefaults.standard.string(forKey: "paywallVariant") ?? "a"
            paywallVariant = PaywallVariant(rawValue: variantString) ?? .a
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
        withAnimation(.easeOut(duration: 0.3)) {
            showOnboarding = false
        }
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasSeenOnboardingKey)
        showOnboarding = true
    }
    
    // MARK: - Navigation Helpers
    
    func navigateToDashboard() {
        selectedTab = .dashboard
    }
    
    func navigateToPhotos() {
        selectedTab = .photos
    }
    
    func navigateToSettings() {
        selectedTab = .settings
    }
    
    func presentPaywall() {
        showPaywall = true
    }
    
    func dismissPaywall() {
        showPaywall = false
    }
    
    // MARK: - Permission Requests
    
    func requestPermission(for type: PermissionType) {
        currentPermissionType = type
        showPermissionModal = true
    }
    
    func dismissPermissionModal() {
        showPermissionModal = false
        currentPermissionType = nil
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case photos = "Photos"
    case storage = "Storage"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .photos: return "photo.fill"
        case .storage: return "externaldrive.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var title: String { rawValue }
}

// MARK: - Paywall Variant

enum PaywallVariant: String {
    case a = "a"
    case b = "b"
}

// MARK: - Permission Type

enum PermissionType: String {
    case photos = "Photos"
    case contacts = "Contacts"
    case notifications = "Notifications"
    
    var icon: String {
        switch self {
        case .photos: return "photo.fill"
        case .contacts: return "person.crop.circle.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    var title: String {
        switch self {
        case .photos: return "Access Your Photos"
        case .contacts: return "Access Your Contacts"
        case .notifications: return "Enable Notifications"
        }
    }
    
    var description: String {
        switch self {
        case .photos: return "We need access to your photos to find duplicates, similar photos, and help you free up storage space."
        case .contacts: return "We need access to your contacts to find and merge duplicates, remove empty contacts."
        case .notifications: return "Enable notifications to get alerts about storage status, cleaning reminders, and special offers."
        }
    }
}

// MARK: - Navigation Destinations

enum DashboardDestination: Hashable {
    case photosCleaner
    case videosCleaner
    case contactsCleaner
    case emailCleaner
    case secretFolder
    case storageOverview
    case battery
}

enum PhotosDestination: Hashable {
    case duplicates
    case similar
    case screenshots
    case livePhotos
    case burst
    case bigFiles
    case swipeClean
}

