# Требования: Настройка проекта

## Цель
Создать iOS-проект для приложения-клинера с архитектурой MVVM, SwiftUI, интеграцией Apphud и AppsFlyer.

---

## Требование 1: Создание проекта

### Xcode Project
- **Тип:** iOS App
- **Interface:** SwiftUI
- **Language:** Swift
- **Minimum Deployment:** iOS 17.0
- **Orientation:** Portrait only (iPhone), All (iPad)
- **Bundle Identifier:** формат `com.company.appname`

### Структура директорий
```
AppName/
├── Core/
│   ├── Extensions/
│   ├── Navigation/
│   ├── Services/
│   ├── Theme/
│   └── Utilities/
├── Features/
│   ├── CleaningHistory/
│   │   └── Views/
│   ├── Contacts/
│   │   └── Views/
│   ├── Dashboard/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── DeviceHealth/
│   │   └── Views/
│   ├── Main/
│   ├── Onboarding/
│   │   └── Views/
│   ├── Paywall/
│   │   └── Views/
│   ├── Photos/
│   │   └── Views/
│   ├── SecretSpace/
│   │   └── Views/
│   ├── Splash/
│   │   └── Views/
│   ├── Swipe/
│   │   └── Views/
│   └── Videos/
│       └── Views/
├── UI/
│   └── Components/
│       ├── Backgrounds/
│       ├── Buttons/
│       ├── Cards/
│       ├── Common/
│       ├── Modals/
│       └── Progress/
├── Assets.xcassets/
└── Info.plist
```

---

## Требование 2: Зависимости (Swift Package Manager)

### ApphudSDK
- **URL:** `https://github.com/apphud/ApphudSDK`
- **Version:** последняя стабильная (4.x+)
- **Назначение:** управление подписками, paywall, receipt validation

### AppsFlyerFramework-Dynamic
- **URL:** `https://github.com/AppsFlyerSDK/AppsFlyerFramework-Dynamic`
- **Version:** последняя стабильная (6.x+)
- **Назначение:** mobile attribution, аналитика, ATT интеграция

### Подключение:
1. Xcode → File → Add Package Dependencies
2. Добавить оба URL
3. Убедиться, что targets правильно связаны

---

## Требование 3: Info.plist

### Privacy Usage Descriptions (обязательно)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to find duplicates and free up space on your device.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save optimized photos to your library.</string>

<key>NSContactsUsageDescription</key>
<string>We need access to your contacts to find and remove duplicates.</string>

<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to unlock your Secret Folder and keep your private content secure.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>We'll send you reminders to clean your device and keep it optimized.</string>

<key>NSUserTrackingUsageDescription</key>
<string>Your data will be used to provide you a better and personalized ad experience.</string>
```

### AppsFlyer Configuration
```xml
<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://appsflyer-skadnetwork.com/</string>
```

### Другие настройки
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>UIApplicationSupportsMultipleScenes</key>
<false/>

<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleLightContent</string>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>

<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

---

## Требование 4: App Entry Point

### CleanerApp (@main)

```swift
@main
struct CleanerApp: App {
    init() {
        // 1. Инициализировать Apphud
        Apphud.start(apiKey: "YOUR_APPHUD_API_KEY")
        
        // 2. Инициализировать AppsFlyer (ПОСЛЕ Apphud)
        AppsFlyerService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppState.shared)
                .environmentObject(Router.shared)
                .preferredColorScheme(.dark)
        }
    }
}
```

### RootView (управление состоянием)
```
SplashView → OnboardingView → PaywallView → PermissionsView → MainTabView
```

Логика:
1. `showSplash == true` → SplashView
2. `hasCompletedOnboarding == false` → OnboardingView → PaywallView
3. `hasCompletedPermissions == false` → PermissionsRequestView
4. Иначе → MainTabView

### Фоновая загрузка данных
При старте MainTabView параллельно загрузить:
- `PhotoService.shared.updateQuickCounts()`
- `StorageService.shared.refreshStorageInfo()`
- `SubscriptionManager.shared.checkSubscriptionStatus()`
- `BatteryService.shared.setupBatteryMonitoring()`
- `NotificationService.shared.maintainScheduleIfNeeded()`

---

## Требование 5: Цветовая схема

- Приложение работает ТОЛЬКО в тёмной теме
- `.preferredColorScheme(.dark)` на корневом view
- Статус-бар: светлый (UIStatusBarStyleLightContent)

---

## Критерии приёмки

- [ ] Проект создан и компилируется без ошибок
- [ ] Все SPM-зависимости подключены и резолвятся
- [ ] Info.plist содержит все необходимые ключи
- [ ] Структура директорий соответствует спецификации
- [ ] AppDelegate инициализирует SDK
- [ ] RootView корректно переключает состояния
- [ ] Тёмная тема применяется ко всему приложению
