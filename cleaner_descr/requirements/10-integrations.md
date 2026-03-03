# Требования: Интеграции (AppsFlyer, Apphud, системные фреймворки)

## Цель
Описать все внешние интеграции приложения и требования к их реализации.

---

## Интеграция 1: AppsFlyer (Аналитика и атрибуция)

### Документация
- Основная: https://dev.appsflyer.com/hc/docs/ios-sdk
- Swift Package: https://github.com/AppsFlyerSDK/AppsFlyerFramework-Dynamic
- ATT интеграция: https://dev.appsflyer.com/hc/docs/ios-sdk-att

### AppsFlyerService

```swift
@MainActor
class AppsFlyerService: NSObject, ObservableObject, AppsFlyerLibDelegate {
    static let shared = AppsFlyerService()
    
    @Published var conversionData: [AnyHashable: Any]?
    @Published var isATTAuthorized = false
    
    private let devKey = "YOUR_APPSFLYER_DEV_KEY"
    private let appId = "YOUR_APP_STORE_ID"
    
    func configure() {
        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appId
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = false  // true для отладки
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        // Передать identifiers в Apphud
        setDeviceIdentifiersToApphud()
    }
    
    func setDeviceIdentifiersToApphud() {
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        
        if let idfv = idfv {
            Apphud.setDeviceIdentifiers(idfa: idfa, idfv: idfv)
        }
    }
    
    func requestATTPermission() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isATTAuthorized = (status == .authorized)
                self?.start()
            }
        }
    }
    
    func start() {
        AppsFlyerLib.shared().start()
    }
    
    // MARK: - Event Tracking
    
    func logEvent(name: String, values: [String: Any]? = nil) {
        AppsFlyerLib.shared().logEvent(name, withValues: values)
    }
    
    func logPurchase(productId: String, price: Double, currency: String) {
        logEvent(name: AFEventPurchase, values: [
            AFEventParamContentId: productId,
            AFEventParamRevenue: price,
            AFEventParamCurrency: currency
        ])
    }
    
    // MARK: - AppsFlyerLibDelegate
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        conversionData = data
        
        // Передать атрибуцию в Apphud
        Apphud.setAttribution(data: data, from: .appsFlyer) { _ in }
    }
    
    func onConversionDataFail(_ error: Error) {
        print("AppsFlyer conversion data error: \(error)")
    }
}
```

### Порядок инициализации (КРИТИЧНО)
```
1. Apphud.start(apiKey:)          ← ПЕРВЫЙ
2. AppsFlyerService.configure()    ← ПОСЛЕ Apphud
3. ATT запрос (в онбординге)       ← ПОСЛЕ configure
4. AppsFlyerLib.start()            ← ПОСЛЕ ATT
```

### Ключевые события для трекинга
| Событие | Когда | Параметры |
|---------|-------|-----------|
| `af_purchase` | Покупка подписки | productId, revenue, currency |
| `af_complete_registration` | Завершение онбординга | — |
| `scan_completed` | Завершение сканирования | items_found |
| `items_cleaned` | Удаление элементов | count, type |

---

## Интеграция 2: Apphud (Подписки)

### Документация
- Основная: https://docs.apphud.com/docs/ios-sdk
- Swift Package: https://github.com/apphud/ApphudSDK

### Инициализация
```swift
// В App init()
Apphud.start(apiKey: "YOUR_APPHUD_API_KEY")

// Опционально: User ID
// Apphud.start(apiKey: "KEY", userID: "custom_user_id")
```

### Основные методы
```swift
// Проверка подписки
Apphud.hasPremiumAccess() -> Bool

// Загрузка paywalls
Apphud.paywalls() async -> [ApphudPaywall]

// Покупка
Apphud.purchase(_ product: ApphudProduct) async -> ApphudPurchaseResult

// Восстановление
Apphud.restorePurchases() async -> Bool

// Проверка trial
product.isEligibleForIntroductoryOffer() async -> Bool

// Атрибуция
Apphud.setAttribution(data:from:callback:)
Apphud.setDeviceIdentifiers(idfa:idfv:)
```

### Настройка в Apphud Dashboard
1. Создать приложение
2. Добавить продукты (weekly, yearly)
3. Создать paywall с placement
4. Настроить интеграцию с App Store Connect
5. Добавить Shared Secret для receipt validation

---

## Интеграция 3: PhotoKit

### Документация
- https://developer.apple.com/documentation/photokit

### Используемые API
```swift
import Photos

// Запрос разрешения
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in ... }

// Получение фото
PHAsset.fetchAssets(with: .image, options: PHFetchOptions())

// Метаданные
PHAssetResource.assetResources(for: asset)  // размер файла

// Кэширование миниатюр
PHCachingImageManager().startCachingImages(for:targetSize:contentMode:options:)

// Удаление
PHPhotoLibrary.shared().performChanges {
    PHAssetChangeRequest.deleteAssets(assets as NSArray)
}

// Предикаты для фильтрации
NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoLive.rawValue)
NSPredicate(format: "representsBurst == YES")
```

### Ключевые моменты
- `@MainActor` для обновления UI
- `PHCachingImageManager` для производительности
- `PHFetchOptions.sortDescriptors` для сортировки
- Системный диалог при удалении (не кастомизируется)

---

## Интеграция 4: Contacts Framework

### Документация
- https://developer.apple.com/documentation/contacts

### Используемые API
```swift
import Contacts

// Запрос разрешения
CNContactStore().requestAccess(for: .contacts) { granted, error in ... }

// Получение контактов
let keysToFetch: [CNKeyDescriptor] = [
    CNContactGivenNameKey, CNContactFamilyNameKey,
    CNContactPhoneNumbersKey, CNContactEmailAddressesKey,
    CNContactOrganizationNameKey, CNContactNoteKey,
    CNContactImageDataAvailableKey, CNContactThumbnailImageDataKey
] as [CNKeyDescriptor]

let request = CNContactFetchRequest(keysToFetch: keysToFetch)
try store.enumerateContacts(with: request) { contact, _ in ... }

// Удаление
let request = CNSaveRequest()
request.delete(contact.mutableCopy() as! CNMutableContact)
try store.execute(request)

// Создание
let newContact = CNMutableContact()
newContact.givenName = "John"
let request = CNSaveRequest()
request.add(newContact, toContainerWithIdentifier: nil)
try store.execute(request)
```

---

## Интеграция 5: LocalAuthentication (Биометрия)

### Документация
- https://developer.apple.com/documentation/localauthentication

### Используемые API
```swift
import LocalAuthentication

let context = LAContext()
var error: NSError?

// Проверка доступности
let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

// Тип биометрии
context.biometryType  // .faceID, .touchID, .none

// Аутентификация
try await context.evaluatePolicy(
    .deviceOwnerAuthenticationWithBiometrics,
    localizedReason: "Unlock Secret Space"
)
```

---

## Интеграция 6: Keychain Services (Security)

### Документация
- https://developer.apple.com/documentation/security/keychain_services

### Используемые API
```swift
import Security

// Сохранение
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "key_name",
    kSecAttrService as String: Bundle.main.bundleIdentifier!,
    kSecValueData as String: data
]
SecItemAdd(query as CFDictionary, nil)

// Чтение
SecItemCopyMatching(query as CFDictionary, &result)

// Удаление
SecItemDelete(query as CFDictionary)
```

---

## Интеграция 7: UserNotifications

### Документация
- https://developer.apple.com/documentation/usernotifications

### Используемые API
```swift
import UserNotifications

// Запрос разрешения
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])

// Планирование
let content = UNMutableNotificationContent()
content.title = "..."
content.body = "..."
content.sound = .default

let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
let request = UNNotificationRequest(identifier: "...", content: content, trigger: trigger)
UNUserNotificationCenter.current().add(request)

// Удаление всех
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
```

---

## Интеграция 8: AVFoundation (Сжатие видео)

### Документация
- https://developer.apple.com/documentation/avfoundation

### Используемые API
```swift
import AVFoundation

// Экспорт с сжатием
let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetMediumQuality)
export?.outputURL = outputURL
export?.outputFileType = .mp4
await export?.export()
```

---

## Интеграция 9: App Tracking Transparency

### Документация
- https://developer.apple.com/documentation/apptrackingtransparency

### Используемые API
```swift
import AppTrackingTransparency
import AdSupport

// Запрос
ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized: // IDFA доступен
    case .denied, .restricted, .notDetermined: // IDFA недоступен
    }
}

// Получение IDFA (после авторизации)
let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
```

---

## Сводная таблица интеграций

| Интеграция | Тип | Версия | Назначение |
|-----------|-----|--------|------------|
| ApphudSDK | SPM | 4.x | Подписки, paywall |
| AppsFlyerFramework | SPM | 6.x | Атрибуция, аналитика |
| PhotoKit | System | iOS 17+ | Фото/видео |
| Contacts | System | iOS 17+ | Контакты |
| LocalAuthentication | System | iOS 17+ | Биометрия |
| Security (Keychain) | System | iOS 17+ | Безопасное хранение |
| UserNotifications | System | iOS 17+ | Push-уведомления |
| AVFoundation | System | iOS 17+ | Сжатие видео |
| ATT | System | iOS 17+ | App Tracking |

---

## Критерии приёмки

- [ ] AppsFlyer инициализируется ПОСЛЕ Apphud
- [ ] ATT запрашивается в правильный момент (онбординг)
- [ ] Conversion data передаётся в Apphud
- [ ] Все покупки логируются в AppsFlyer
- [ ] Подписки работают через Apphud
- [ ] PhotoKit запрашивает правильный уровень доступа (.readWrite)
- [ ] Биометрия работает на устройствах с Face ID и Touch ID
- [ ] Пароль хранится в Keychain (не в UserDefaults)
- [ ] Уведомления планируются корректно
