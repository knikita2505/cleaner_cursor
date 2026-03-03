# Требования: Навигация и управление состоянием

## Цель
Реализовать систему навигации приложения: TabView, NavigationStack, Router, глобальное состояние.

---

## Требование 1: AppState — Глобальное состояние

### Класс
```swift
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // Онбординг (UserDefaults)
    @Published var hasCompletedOnboarding: Bool
    @Published var hasCompletedPermissions: Bool
    @Published var showSplash: Bool = true
    
    // Табы
    @Published var selectedTab: AppTab = .clean
    
    // Navigation Paths
    @Published var dashboardPath = NavigationPath()
    @Published var photosPath = NavigationPath()
    
    // Разрешения
    @Published var showPermissionModal: Bool = false
    @Published var currentPermissionType: PermissionType?
}
```

### Перечисления

```swift
enum AppTab: Int, CaseIterable, Identifiable {
    case hide = 0       // Secret Space
    case swipe = 1      // Swipe Clean
    case clean = 2      // Dashboard
    case contacts = 3   // Contacts
    case analytics = 4  // Analytics
    
    var id: Int { rawValue }
    var title: String { ... }
    var icon: String { ... }  // SF Symbol name
}

enum PermissionType {
    case photos
    case contacts
    case notifications
}

enum DashboardDestination: Hashable {
    case photosOverview
    case duplicates
    case similar
    case screenshots
    case livePhotos
    case burst
    case bigFiles
    case videos
    case shortVideos
    case highlights
}
```

### Методы
- `completeOnboarding()` — устанавливает `hasCompletedOnboarding = true` в UserDefaults
- `resetOnboarding()` — сбрасывает онбординг (для отладки)
- `navigateToClean()` — переключает на вкладку Clean
- `requestPermission(for:)` — показывает модалку запроса разрешения

### Персистентность
- `hasCompletedOnboarding` → `UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")`
- `hasCompletedPermissions` → `UserDefaults.standard.bool(forKey: "hasCompletedPermissions")`

---

## Требование 2: Router — Координатор навигации

### Класс
```swift
@MainActor
class Router: ObservableObject {
    static let shared = Router()
    
    @Published var sheet: Sheet?
    @Published var fullScreenCover: FullScreenCover?
    
    func push<T: Hashable>(_ destination: T)
    func pop()
    func popToRoot()
    func present(_ sheet: Sheet)
    func dismissSheet()
    func presentFullScreen(_ cover: FullScreenCover)
    func dismissFullScreen()
}

enum Sheet: Identifiable {
    case settings
    case premiumPaywall(PaywallPlacement)
    case featureTip(FeatureTipData)
    // ... другие
    
    var id: String { ... }
}

enum FullScreenCover: Identifiable {
    case paywall(PaywallPlacement)
    case passcode(PasscodeMode)
    // ...
    
    var id: String { ... }
}
```

### ViewModifier для навигации
```swift
struct NavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: DashboardDestination.self) { dest in
                switch dest {
                case .duplicates: DuplicatesView()
                case .similar: SimilarPhotosView()
                // ...
                }
            }
    }
}
```

---

## Требование 3: MainTabView

### Структура
```swift
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            SecretSpaceHomeView()
                .tabItem { Label("Hide", systemImage: "lock.shield.fill") }
                .tag(AppTab.hide)
            
            SwipeHubView()
                .tabItem { Label("Swipe", systemImage: "hand.point.right.fill") }
                .tag(AppTab.swipe)
            
            NavigationStack(path: $appState.dashboardPath) {
                DashboardView()
            }
            .tabItem { Label("Clean", systemImage: "sparkles") }
            .tag(AppTab.clean)
            
            ContactsCleanerView()
                .tabItem { Label("Contacts", systemImage: "person.crop.circle") }
                .tag(AppTab.contacts)
            
            CleaningHistoryView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(AppTab.analytics)
        }
        .onAppear { setupTabBarAppearance() }
        .gesture(swipeGesture)
    }
}
```

### Требования к TabBar:
- Тёмный фон (`backgroundPrimary`)
- Выбранная иконка: `accentBlue`
- Невыбранная иконка: `textTertiary`
- Высота: стандартная iOS

### Swipe-навигация:
- Горизонтальный `DragGesture` на всём контейнере
- Порог: 50pt смещения
- Haptic: `HapticManager.selection()` при переключении
- Граничные условия: не выходить за пределы 0...4

---

## Требование 4: Жизненный цикл запуска

### Последовательность экранов

```
1. SplashView (2-3 сек)
   ↓ onComplete
2. if !hasCompletedOnboarding:
   OnboardingView (4 страницы + ATT)
   ↓ Continue
3. PaywallView (онбординг-paywall)
   ↓ Subscribe / Skip
4. if !hasCompletedPermissions:
   PermissionsRequestView
   - Photos (обязательно)
   - Contacts (обязательно)
   - Notifications (опционально)
   ↓ All granted
5. MainTabView (основной интерфейс)
```

### PermissionsRequestView
- Показывается после онбординга
- Три типа разрешений с модальными окнами
- Каждое разрешение запрашивается системным диалогом
- При отказе — показ `PermissionModal` с объяснением и кнопкой "Open Settings"
- `openURL(URL(string: UIApplication.openSettingsURLString)!)` для открытия настроек

---

## Требование 5: Фоновая инициализация

При первом отображении MainTabView запустить:
```swift
func startBackgroundLoading() {
    Task {
        await PhotoService.shared.updateQuickCounts()
    }
    Task {
        StorageService.shared.refreshStorageInfo()
    }
    Task {
        SubscriptionManager.shared.checkSubscriptionStatus()
    }
    Task {
        BatteryService.shared.setupBatteryMonitoring()
    }
    Task {
        NotificationService.shared.maintainScheduleIfNeeded()
    }
}
```

---

## Критерии приёмки

- [ ] AppState корректно сохраняет/загружает состояние из UserDefaults
- [ ] TabView показывает 5 вкладок с правильными иконками
- [ ] Swipe-навигация между вкладками работает плавно
- [ ] NavigationStack работает в каждой вкладке
- [ ] Router корректно показывает/скрывает sheets и full-screen covers
- [ ] Онбординг показывается только при первом запуске
- [ ] Разрешения запрашиваются после онбординга
- [ ] Фоновая загрузка не блокирует UI
