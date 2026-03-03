# Требования: Подписки и Paywall

## Цель
Реализовать систему монетизации: Freemium модель с дневным лимитом, интеграция с Apphud для подписок, два варианта paywall.

---

## Требование 1: SubscriptionManager

### Класс
```swift
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    @Published var paywallPlacement: PaywallPlacement = .onboarding
    
    let dailyFreeLimit = 50
    
    // UserDefaults keys
    private let dailyCountKey = "daily_cleaned_count"
    private let dailyDateKey = "daily_cleaned_date"
}
```

### Перечисления
```swift
enum PaywallPlacement {
    case onboarding        // После онбординга (full screen)
    case premiumFeature    // При доступе к премиум-функции (sheet)
    case reachedLimits     // При превышении лимита (sheet)
}

enum PremiumFeature {
    case unlimitedCleaning
    case analytics
    case secretSpace
    case advancedScan
}

enum CleaningPermission {
    case allowed
    case limitReached(remaining: Int)
    case premiumRequired
}
```

### Проверка статуса
```swift
func checkSubscriptionStatus() {
    isPremium = Apphud.hasPremiumAccess()
}
```

### Лимиты
```swift
func canCleanItems(count: Int) -> CleaningPermission {
    if isPremium { return .allowed }
    
    let todayUsed = getTodayCleanedCount()
    let remaining = dailyFreeLimit - todayUsed
    
    if remaining >= count { return .allowed }
    if remaining > 0 { return .limitReached(remaining: remaining) }
    return .limitReached(remaining: 0)
}

func recordCleanedItems(count: Int) {
    resetDailyCountIfNeeded()
    let current = UserDefaults.standard.integer(forKey: dailyCountKey)
    UserDefaults.standard.set(current + count, forKey: dailyCountKey)
}

private func getTodayCleanedCount() -> Int {
    resetDailyCountIfNeeded()
    return UserDefaults.standard.integer(forKey: dailyCountKey)
}

private func resetDailyCountIfNeeded() {
    let lastDate = UserDefaults.standard.object(forKey: dailyDateKey) as? Date ?? Date.distantPast
    if !Calendar.current.isDateInToday(lastDate) {
        UserDefaults.standard.set(0, forKey: dailyCountKey)
        UserDefaults.standard.set(Date(), forKey: dailyDateKey)
    }
}
```

### Показ Paywall
```swift
func showPaywall(for placement: PaywallPlacement) {
    paywallPlacement = placement
    showPaywall = true
}

func dismissPaywall() {
    showPaywall = false
}

// Обработка попытки очистки
func handleCleaningAttempt(count: Int) -> CleaningPermission {
    let permission = canCleanItems(count: count)
    
    switch permission {
    case .allowed:
        return .allowed
    case .limitReached:
        showPaywall(for: .reachedLimits)
        return permission
    case .premiumRequired:
        showPaywall(for: .premiumFeature)
        return permission
    }
}
```

### ViewModifier для премиум-функций
```swift
struct PremiumFeatureModifier: ViewModifier {
    @ObservedObject var manager = SubscriptionManager.shared
    let feature: PremiumFeature
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if !manager.isPremium {
                    // Blur + замок + кнопка "Unlock Premium"
                }
            }
    }
}
```

### RemainingItemsView (виджет)
```swift
struct RemainingItemsView: View {
    @ObservedObject var manager = SubscriptionManager.shared
    
    var body: some View {
        if !manager.isPremium {
            HStack {
                Text("Today: \(manager.getTodayCleanedCount())/\(manager.dailyFreeLimit)")
                ProgressView(value: Double(used) / Double(total))
            }
        }
    }
}
```

---

## Требование 2: PaywallView (Онбординг)

### UI компоненты
1. **Фон:** `AuroraBackground` (анимированный градиент)
2. **Анимация хранилища:** Циклический прогресс-бар "до/после" очистки
3. **Планы подписки:**
   - Weekly (еженедельная) — карточка с ценой
   - Yearly (годовая) — карточка с ценой + бейдж "Best Value"
4. **CTA кнопка:** "Start Free Trial" или "Subscribe" (PrimaryButton)
5. **Ссылки:** Terms of Use, Privacy Policy, Restore Purchases

### ViewModel
```swift
class PaywallViewModel: ObservableObject {
    @Published var products: [ApphudProduct] = []
    @Published var selectedPlan: PaywallSubscriptionPlan = .yearly
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var error: PaywallError?
    @Published var isTrialEligible = false
    
    let placement: PaywallPlacement
    
    init(placement: PaywallPlacement) {
        self.placement = placement
    }
    
    func loadProducts() async {
        isLoading = true
        
        // Загрузка products через Apphud
        let paywalls = await Apphud.paywalls()
        // Фильтрация по placement
        // Маппинг в ApphudProduct
        
        isLoading = false
    }
    
    func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        
        let result = await Apphud.purchase(product)
        
        if result.success {
            SubscriptionManager.shared.isPremium = true
            // Закрыть paywall
        } else if let error = result.error {
            self.error = .purchaseFailed(error.localizedDescription)
        }
        
        isPurchasing = false
    }
    
    func restore() async {
        let result = await Apphud.restorePurchases()
        if Apphud.hasPremiumAccess() {
            SubscriptionManager.shared.isPremium = true
        }
    }
    
    func checkTrialEligibility() async {
        // Проверка через StoreKit / Apphud
        isTrialEligible = await product.isEligibleForIntroductoryOffer()
    }
}
```

### Product IDs
```swift
struct PaywallConstants {
    static let weeklyProductId = "com.yourapp.weekly"
    static let yearlyProductId = "com.yourapp.yearly"
    static let termsURL = "https://yourapp.com/terms"
    static let privacyURL = "https://yourapp.com/privacy"
}
```

### Форматирование цен
```swift
func formatPrice(_ product: ApphudProduct) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = product.skProduct?.priceLocale
    return formatter.string(from: product.skProduct?.price ?? 0) ?? ""
}
```

---

## Требование 3: PremiumPaywallView (In-app)

### Отличия от онбординг-paywall
- Показывается как `.sheet` (не full screen)
- Список преимуществ (feature bullets):
  - Unlimited cleaning
  - Advanced analytics  
  - Secret Space
  - No ads
- Контекстное сообщение в зависимости от `PaywallPlacement`
- Более компактный UI

---

## Требование 4: Интеграция с Apphud

### Инициализация
```swift
// В App init()
Apphud.start(apiKey: "YOUR_API_KEY")

// Опционально: передать user ID
Apphud.setUserProperty(key: .init("user_id"), value: userId)
```

### Проверка подписки
```swift
// Автоматическая проверка при запуске
func checkSubscriptionStatus() {
    isPremium = Apphud.hasPremiumAccess()
}

// Альтернативно через subscription object
if let subscription = Apphud.subscription() {
    isPremium = subscription.isActive()
}
```

### Обработка покупки
```swift
let result = await Apphud.purchase(product)

if result.success {
    // Подписка активирована
    isPremium = true
    AppsFlyerService.shared.logPurchase(
        productId: product.productId,
        price: product.skProduct?.price.doubleValue ?? 0,
        currency: product.skProduct?.priceLocale.currency?.identifier ?? "USD"
    )
} else {
    // Обработка ошибки
}
```

---

## Требование 5: Логика Freemium

### Правила
1. **Бесплатно без лимита:**
   - Сканирование (просмотр результатов)
   - Secret Space (создание, пароль)
   - Просмотр фото в Swipe (без удаления)
   - Device Health (базовый)

2. **Бесплатно с лимитом (50/день):**
   - Удаление фото/видео
   - Удаление контактов
   - Объединение контактов

3. **Только Premium:**
   - Cleaning Analytics (вкладка Analytics)
   - Безлимитная очистка
   - (опционально) расширенные функции Secret Space

### Точки показа Paywall
1. После онбординга (onboarding)
2. При попытке удалить >50 элементов за день (reachedLimits)
3. При открытии Analytics без подписки (premiumFeature)
4. При доступе к премиум-функции (premiumFeature)

---

## Критерии приёмки

- [ ] Apphud SDK инициализируется при запуске
- [ ] Подписка проверяется через `Apphud.hasPremiumAccess()`
- [ ] Дневной лимит: 50 элементов, сброс в полночь
- [ ] PaywallView загружает цены из Apphud
- [ ] Покупка обрабатывается корректно (success + error)
- [ ] Restore purchases работает
- [ ] PremiumPaywallView показывается при ограничениях
- [ ] Покупки логируются в AppsFlyer
- [ ] Free trial отображается если пользователь eligible
- [ ] Ссылки Terms/Privacy открываются в Safari
