import Foundation
import SwiftUI
import ApphudSDK

// MARK: - Subscription Manager

/// Centralized manager for subscription logic, limits, and paywall presentation
@MainActor
final class SubscriptionManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    /// Whether user has active premium subscription
    @Published private(set) var isPremium: Bool = false
    
    /// Number of items cleaned today (for free users)
    @Published private(set) var itemsCleanedToday: Int = 0
    
    /// Whether paywall is currently being presented
    @Published var showPaywall: Bool = false
    
    /// Current paywall placement to show
    @Published var currentPlacement: PaywallPlacement = .onboarding
    
    // MARK: - Constants
    
    /// Daily limit for free users
    nonisolated static let dailyFreeLimit: Int = 50
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let itemsCleanedToday = "subscription.itemsCleanedToday"
        static let lastCleanedDate = "subscription.lastCleanedDate"
        static let hasSeenOnboardingPaywall = "subscription.hasSeenOnboardingPaywall"
    }
    
    // MARK: - Computed Properties
    
    /// Remaining items for today
    var remainingItems: Int {
        isPremium ? Int.max : max(0, Self.dailyFreeLimit - itemsCleanedToday)
    }
    
    /// Whether user has reached daily limit
    var hasReachedLimit: Bool {
        !isPremium && itemsCleanedToday >= Self.dailyFreeLimit
    }
    
    /// Formatted remaining items text
    var remainingItemsText: String {
        if isPremium {
            return "Unlimited"
        }
        return "\(remainingItems)/\(Self.dailyFreeLimit)"
    }
    
    // MARK: - Init
    
    private init() {
        loadLocalState()
        checkSubscriptionStatus()
        
        // Listen to Apphud subscription changes
        setupApphudObserver()
    }
    
    // MARK: - Public Methods
    
    /// Check and refresh subscription status from Apphud
    func checkSubscriptionStatus() {
        // Check if user has active subscription
        let hasActiveSubscription = Apphud.hasActiveSubscription()
        
        if isPremium != hasActiveSubscription {
            isPremium = hasActiveSubscription
            print("📦 [Subscription] Premium status: \(isPremium)")
        }
        
        // Reset daily limit if needed
        checkAndResetDailyLimit()
    }
    
    /// Check if user can clean specified number of items
    /// - Parameter count: Number of items to clean
    /// - Returns: True if user can clean, false if limit would be exceeded
    func canCleanItems(count: Int) -> Bool {
        if isPremium { return true }
        return itemsCleanedToday + count <= Self.dailyFreeLimit
    }
    
    /// Record cleaned items and update limit
    /// - Parameter count: Number of items cleaned
    /// - Returns: True if successful, false if limit exceeded
    @discardableResult
    func recordCleanedItems(count: Int) -> Bool {
        if isPremium { return true }
        
        guard canCleanItems(count: count) else {
            return false
        }
        
        itemsCleanedToday += count
        saveLocalState()
        
        print("📦 [Subscription] Cleaned \(count) items. Total today: \(itemsCleanedToday)/\(Self.dailyFreeLimit)")
        
        return true
    }
    
    /// Check if this is the last item in limit
    /// - Parameter count: Number of items about to be cleaned
    /// - Returns: True if cleaning these items would reach the limit
    func isLastItemsInLimit(count: Int) -> Bool {
        if isPremium { return false }
        return itemsCleanedToday + count == Self.dailyFreeLimit
    }
    
    /// Check if user can access premium feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        if isPremium { return true }
        return !feature.requiresPremium
    }
    
    // MARK: - Paywall Presentation
    
    /// Show paywall for specific placement
    /// - Parameter placement: The placement context for the paywall
    func showPaywall(for placement: PaywallPlacement) {
        guard !isPremium else {
            print("📦 [Subscription] User is premium, not showing paywall")
            return
        }
        
        currentPlacement = placement
        showPaywall = true
        print("📦 [Subscription] Showing paywall for placement: \(placement.identifier)")
    }
    
    /// Dismiss paywall
    func dismissPaywall() {
        showPaywall = false
    }
    
    /// Check and show onboarding paywall if needed
    /// - Returns: True if paywall was shown
    @discardableResult
    func checkAndShowOnboardingPaywall() -> Bool {
        guard !isPremium else { return false }
        
        showPaywall(for: .onboarding)
        return true
    }
    
    /// Handle attempt to access premium feature
    /// - Parameter feature: The feature user is trying to access
    /// - Returns: True if access is granted, false if paywall was shown
    @discardableResult
    func handlePremiumFeatureAccess(_ feature: PremiumFeature) -> Bool {
        if canAccessFeature(feature) {
            return true
        }
        
        showPaywall(for: .premiumFeature)
        return false
    }
    
    /// Handle attempt to clean items when limit is reached or about to be reached
    /// - Parameter count: Number of items to clean
    /// - Returns: CleaningPermission indicating what action to take
    func handleCleaningAttempt(count: Int) -> CleaningPermission {
        if isPremium {
            return .allowed
        }
        
        if hasReachedLimit {
            return .limitReached
        }
        
        if !canCleanItems(count: count) {
            return .insufficientLimit(remaining: remainingItems, requested: count)
        }
        
        if isLastItemsInLimit(count: count) {
            return .lastItems
        }
        
        return .allowed
    }
    
    // MARK: - Purchase Handling
    
    /// Handle successful purchase - called from PaywallView
    func handleSuccessfulPurchase() {
        checkSubscriptionStatus()
        dismissPaywall()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    /// Restore purchases
    func restorePurchases() async -> Bool {
        return await withCheckedContinuation { continuation in
            Apphud.restorePurchases { result in
                DispatchQueue.main.async {
                    self.checkSubscriptionStatus()
                    
                    if self.isPremium {
                        self.dismissPaywall()
                        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupApphudObserver() {
        // Apphud automatically notifies about subscription changes
        // We check status on app foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkSubscriptionStatus()
            }
        }
    }
    
    private func loadLocalState() {
        let defaults = UserDefaults.standard
        
        // Load items cleaned today
        itemsCleanedToday = defaults.integer(forKey: Keys.itemsCleanedToday)
        
        // Check if we need to reset (new day)
        checkAndResetDailyLimit()
    }
    
    private func saveLocalState() {
        let defaults = UserDefaults.standard
        defaults.set(itemsCleanedToday, forKey: Keys.itemsCleanedToday)
        defaults.set(Date(), forKey: Keys.lastCleanedDate)
    }
    
    private func checkAndResetDailyLimit() {
        let defaults = UserDefaults.standard
        
        guard let lastDate = defaults.object(forKey: Keys.lastCleanedDate) as? Date else {
            // First time, save current date
            defaults.set(Date(), forKey: Keys.lastCleanedDate)
            return
        }
        
        // Check if 24 hours have passed
        let hoursSinceLastClean = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        
        if hoursSinceLastClean >= 24 {
            print("📦 [Subscription] 24 hours passed, resetting daily limit")
            itemsCleanedToday = 0
            defaults.set(0, forKey: Keys.itemsCleanedToday)
            defaults.set(Date(), forKey: Keys.lastCleanedDate)
        }
    }
}

// MARK: - Supporting Types

/// Paywall placement contexts
enum PaywallPlacement: String {
    case onboarding = "onboarding"
    case premiumFeature = "premium_feature"
    case reachedLimits = "reached_limits"
    
    var identifier: String { rawValue }
}

/// Premium features that require subscription
enum PremiumFeature {
    case secretStorage
    case contacts
    case deviceHealth
    case cleaningHistory  // Now free - Tips section
    case unlimitedCleaning
    
    var requiresPremium: Bool {
        switch self {
        case .secretStorage, .contacts, .deviceHealth, .unlimitedCleaning:
            return true
        case .cleaningHistory:
            // Tips section is now free
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .secretStorage:
            return "Secret Storage"
        case .contacts:
            return "Contact Management"
        case .deviceHealth:
            return "Device Health"
        case .cleaningHistory:
            return "Cleaning Analytics"
        case .unlimitedCleaning:
            return "Unlimited Cleaning"
        }
    }
}

/// Result of checking cleaning permission
enum CleaningPermission {
    case allowed
    case lastItems
    case limitReached
    case insufficientLimit(remaining: Int, requested: Int)
    
    var canProceed: Bool {
        switch self {
        case .allowed, .lastItems:
            return true
        case .limitReached, .insufficientLimit:
            return false
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

// MARK: - View Modifier for Premium Features

/// View modifier that shows paywall when tapping on premium feature
struct PremiumFeatureModifier: ViewModifier {
    let feature: PremiumFeature
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPremiumAlert = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if !subscriptionManager.canAccessFeature(feature) {
                    subscriptionManager.showPaywall(for: .premiumFeature)
                }
            }
            .allowsHitTesting(subscriptionManager.canAccessFeature(feature) ? true : true)
    }
}

extension View {
    /// Apply premium feature restriction
    func premiumFeature(_ feature: PremiumFeature) -> some View {
        modifier(PremiumFeatureModifier(feature: feature))
    }
}

// MARK: - Remaining Items View Component

/// A small view showing remaining items for today
struct RemainingItemsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        if !subscriptionManager.isPremium {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(itemsColor)
                
                Text(subscriptionManager.remainingItemsText)
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(itemsColor)
                
                Text("left today")
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.white.opacity(0.50))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
            )
        }
    }
    
    private var itemsColor: Color {
        let remaining = subscriptionManager.remainingItems
        if remaining <= 5 {
            return Color(hex: "FF5252") // Red
        } else if remaining <= 15 {
            return Color(hex: "FFB74D") // Orange
        } else {
            return Color(hex: "4CAF50") // Green
        }
    }
}

// MARK: - Limit Warning Alert

/// Alert content for showing limit warnings
struct LimitWarningContent {
    let title: String
    let message: String
    let primaryButton: String
    let secondaryButton: String?
    
    static let lastItems = LimitWarningContent(
        title: "Last Free Items",
        message: "This will use your remaining free items for today. Upgrade to Premium for unlimited cleaning.",
        primaryButton: "Continue",
        secondaryButton: "Get Premium"
    )
    
    static let limitReached = LimitWarningContent(
        title: "Daily Limit Reached",
        message: "You've reached your daily limit of \(SubscriptionManager.dailyFreeLimit) items. Upgrade to Premium for unlimited cleaning.",
        primaryButton: "Get Premium",
        secondaryButton: "OK"
    )
    
    static func insufficientLimit(remaining: Int, requested: Int) -> LimitWarningContent {
        LimitWarningContent(
            title: "Not Enough Items Left",
            message: "You want to clean \(requested) items but only have \(remaining) left today. Upgrade to Premium for unlimited cleaning.",
            primaryButton: "Get Premium",
            secondaryButton: "OK"
        )
    }
}
