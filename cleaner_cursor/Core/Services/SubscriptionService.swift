import Foundation
import StoreKit

// MARK: - Subscription Service
/// Сервис для работы с подписками через StoreKit 2

@MainActor
final class SubscriptionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var isPremium: Bool = false
    
    // MARK: - Product IDs
    
    enum ProductID: String, CaseIterable {
        case weekly = "com.cleaner.subscription.weekly"
        case yearly = "com.cleaner.subscription.yearly"
        case lifetime = "com.cleaner.lifetime"
    }
    
    // MARK: - Singleton
    
    static let shared = SubscriptionService()
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Free Tier Limits
    
    private let freeCleaningLimit = 50
    @Published var cleanedTodayCount: Int = 0
    
    // MARK: - Init
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
        
        loadDailyCleaningCount()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self = self else { return }
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = purchasedIDs
        isPremium = !purchasedIDs.isEmpty
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw SubscriptionError.verificationFailed
        }
    }
    
    // MARK: - Free Tier Management
    
    var canCleanMore: Bool {
        isPremium || cleanedTodayCount < freeCleaningLimit
    }
    
    var remainingFreeCleans: Int {
        max(0, freeCleaningLimit - cleanedTodayCount)
    }
    
    func recordCleaning(count: Int = 1) {
        guard !isPremium else { return }
        cleanedTodayCount += count
        saveDailyCleaningCount()
    }
    
    private func loadDailyCleaningCount() {
        let lastDate = UserDefaults.standard.object(forKey: "lastCleaningDate") as? Date ?? Date.distantPast
        
        if !Calendar.current.isDateInToday(lastDate) {
            cleanedTodayCount = 0
            saveDailyCleaningCount()
        } else {
            cleanedTodayCount = UserDefaults.standard.integer(forKey: "cleanedTodayCount")
        }
    }
    
    private func saveDailyCleaningCount() {
        UserDefaults.standard.set(cleanedTodayCount, forKey: "cleanedTodayCount")
        UserDefaults.standard.set(Date(), forKey: "lastCleaningDate")
    }
    
    // MARK: - Product Helpers
    
    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }
    
    var weeklyProduct: Product? {
        product(for: .weekly)
    }
    
    var yearlyProduct: Product? {
        product(for: .yearly)
    }
    
    var lifetimeProduct: Product? {
        product(for: .lifetime)
    }
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Purchase verification failed"
        case .purchaseFailed: return "Purchase failed"
        }
    }
}

// MARK: - Product Extension

extension Product {
    var formattedPrice: String {
        displayPrice
    }
    
    var periodDescription: String? {
        guard let subscription = subscription else { return nil }
        
        switch subscription.subscriptionPeriod.unit {
        case .day:
            return subscription.subscriptionPeriod.value == 7 ? "week" : "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return nil
        }
    }
}

