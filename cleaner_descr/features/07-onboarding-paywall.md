# Функция: Onboarding & Paywall — Онбординг и экраны подписки

## Общее описание

Онбординг — многостраничный экран первого знакомства с приложением. Paywall — экран подписки, интегрированный с Apphud SDK. Два варианта: онбординг-paywall и премиум-paywall (для ограничений).

**Файлы реализации:**
- `Features/Onboarding/Views/OnboardingView.swift` — онбординг
- `Features/Paywall/Views/PaywallView.swift` — основной paywall
- `Features/Paywall/Views/PremiumPaywallView.swift` — премиум paywall
- `Features/Splash/Views/SplashView.swift` — экран загрузки
- `Core/Services/SubscriptionManager.swift` — менеджер подписок (450 строк)

---

## Блок 1: Splash Screen

**Что отображает:**
- Анимированная шестерня (вращение)
- Частицы пыли и искры
- Прогресс-бар загрузки
- Название приложения "MagicSwipe"

**Техническая реализация:**
- Длительность: ~2-3 секунды
- Анимации через `withAnimation()` и `Timer`
- Модели частиц: `SparkleParticle`, `DustParticle`
- Callback `onComplete` для перехода к следующему экрану

---

## Блок 2: Onboarding (4 экрана)

### Экран 1: Welcome
- Заголовок: приветствие
- Описание возможностей приложения
- Иллюстрация

### Экран 2: Photos
- Описание функции очистки фото
- Демонстрация поиска дубликатов

### Экран 3: Storage
- Визуализация экономии места
- Анимированный прогресс-бар

### Экран 4: Features
- Обзор всех функций
- Кнопка "Continue"
- Запрос ATT (App Tracking Transparency) на этом экране

**Навигация:**
- `TabView` с `PageTabViewStyle`
- `SegmentedProgress` — кастомный индикатор страниц
- Кнопка "Next" / "Continue"
- Свайп между страницами

**ATT запрос:**
```swift
func requestATTPermission() {
    AppsFlyerService.shared.requestATTPermission()
    // ATTrackingManager.requestTrackingAuthorization { status in ... }
}
```

---

## Блок 3: Paywall (Онбординг)

**Что отображает:**
- Анимированная визуализация экономии места
- Два плана подписки:
  - Weekly (еженедельная)
  - Yearly (годовая) — с пометкой "Best Value"
- Цены, загруженные из Apphud
- Кнопка "Start Free Trial" / "Subscribe"
- Ссылки: Terms of Use, Privacy Policy, Restore Purchases

**Техническая реализация:**

```swift
enum PaywallSubscriptionPlan {
    case weekly
    case yearly
}

class PaywallViewModel: ObservableObject {
    @Published var products: [ApphudProduct] = []
    @Published var selectedPlan: PaywallSubscriptionPlan = .yearly
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var error: PaywallError?
    @Published var isTrialEligible = false
    
    func loadProducts() {
        // Apphud.paywalls { paywalls in ... }
        // Фильтрация продуктов по placement
    }
    
    func purchaseSelected() {
        // Apphud.purchase(product) { result in ... }
    }
    
    func restore() {
        // Apphud.restorePurchases { ... }
    }
}
```

**Product IDs (константы):**
```swift
struct PaywallConstants {
    static let weeklyProductId = "com.app.weekly"
    static let yearlyProductId = "com.app.yearly"
    static let termsURL = "https://..."
    static let privacyURL = "https://..."
}
```

**Анимация прогресса:**
- Циклическая анимация прогресс-бара хранилища
- `runIntroAnimation()` → `runAnimationCycle()`
- Показывает "до и после" использования приложения

---

## Блок 4: Premium Paywall (In-app)

**Когда показывается:**
- При попытке доступа к премиум-функции
- При превышении дневного лимита очистки (50 элементов)
- При доступе к аналитике (Cleaning History)

**Отличия от онбординг-paywall:**
- Компактный UI (sheet, не full screen)
- Секция преимуществ (feature list)
- Контекстное сообщение ("Unlock unlimited cleaning")

**Placement (контексты показа):**
```swift
enum PaywallPlacement {
    case onboarding         // после онбординга
    case premiumFeature     // доступ к премиум-функции
    case reachedLimits      // превышение дневного лимита
}
```

---

## Блок 5: Subscription Manager

**Ответственность:**
- Проверка статуса подписки
- Управление дневными лимитами
- Показ/скрытие paywall
- Запись использованных элементов

**Ключевые методы:**
```swift
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    @Published var paywallPlacement: PaywallPlacement = .onboarding
    
    let dailyFreeLimit = 50
    
    func checkSubscriptionStatus() {
        isPremium = Apphud.hasPremiumAccess()
    }
    
    func canCleanItems(count: Int) -> CleaningPermission {
        if isPremium { return .allowed }
        let todayUsed = getTodayCleanedCount()
        if todayUsed + count <= dailyFreeLimit { return .allowed }
        return .limitReached(remaining: dailyFreeLimit - todayUsed)
    }
    
    func recordCleanedItems(count: Int) {
        // Увеличить счётчик на сегодня
        // Сброс счётчика в полночь
    }
}
```

**Хранение лимитов:**
- UserDefaults: `"daily_cleaned_count"`, `"daily_cleaned_date"`
- Сброс при изменении даты

---

## Жизненный цикл первого запуска

1. **SplashView** → анимация загрузки (2-3 сек)
2. **OnboardingView** → 4 экрана обучения + ATT запрос
3. **PaywallView** → предложение подписки
4. **PermissionsRequestView** → запрос разрешений (Photos, Contacts, Notifications)
5. **MainTabView** → основной интерфейс

Переход между этапами управляется через `AppState`:
```swift
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var hasCompletedPermissions: Bool
    @Published var showSplash: Bool
}
```
