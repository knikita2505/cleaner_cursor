import Foundation
import UIKit
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport
import ApphudSDK

// MARK: - AppsFlyer Service
/// Сервис для интеграции AppsFlyer MMP с поддержкой ATT и передачей атрибуции в Apphud

@MainActor
final class AppsFlyerService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppsFlyerService()
    
    // MARK: - Configuration
    
    /// AppsFlyer Dev Key (получить в AppsFlyer Dashboard)
    private let devKey = "w2UscaGb7uRH4EtJUmWBj9"
    
    /// Apple App ID (без "id" префикса)
    private let appID = "6757766790"
    
    // MARK: - Published Properties
    
    @Published private(set) var isInitialized = false
    @Published private(set) var attStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published private(set) var hasRequestedATT = false
    
    // MARK: - Private Properties
    
    private var isConfigured = false
    private var hasSetDeviceIdentifiers = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Конфигурирует AppsFlyer SDK. Вызывать в App init() после Apphud.start()
    func configure() {
        guard !isConfigured else {
            print("📊 [AppsFlyer] Already configured")
            return
        }
        
        // Основные настройки
        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appID
        
        // Устанавливаем делегат для получения conversion data
        AppsFlyerLib.shared().delegate = self
        
        // Ждем ATT перед отправкой данных (60 секунд таймаут)
        // Это позволяет SDK дождаться решения пользователя по ATT
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        // Связываем Customer User ID с Apphud User ID
        let apphudUserID = Apphud.userID()
        AppsFlyerLib.shared().customerUserID = apphudUserID
        print("📊 [AppsFlyer] Set Customer User ID: \(apphudUserID)")
        
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif
        
        // Слушаем активацию приложения для запуска SDK
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Передаем Device Identifiers в Apphud сразу после инициализации
        // IDFV всегда доступен, IDFA - только после ATT
        setDeviceIdentifiersToApphud()
        
        isConfigured = true
        isInitialized = true
        
        print("📊 [AppsFlyer] Configured successfully")
        print("📊 [AppsFlyer] Dev Key: \(devKey.prefix(8))...")
        print("📊 [AppsFlyer] App ID: \(appID)")
    }
    
    // MARK: - Device Identifiers (Required by Apphud)
    
    /// Передает IDFA и IDFV в Apphud для корректной атрибуции
    /// Вызывается после инициализации и после получения ATT разрешения
    func setDeviceIdentifiersToApphud() {
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        var idfa: String? = nil
        
        // IDFA доступен только если пользователь дал разрешение ATT
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                // Проверяем что IDFA не нулевой (00000000-0000-0000-0000-000000000000)
                if idfa == "00000000-0000-0000-0000-000000000000" {
                    idfa = nil
                }
            }
        } else {
            // До iOS 14 IDFA доступен если не включен Limit Ad Tracking
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
        }
        
        // Передаем идентификаторы в Apphud
        Apphud.setDeviceIdentifiers(idfa: idfa, idfv: idfv)
        
        hasSetDeviceIdentifiers = true
        print("📊 [AppsFlyer] Device identifiers sent to Apphud - IDFA: \(idfa ?? "nil"), IDFV: \(idfv ?? "nil")")
    }
    
    // MARK: - ATT Request
    
    /// Запрашивает разрешение App Tracking Transparency
    /// Рекомендуется вызывать на последнем экране онбординга
    func requestATTPermission() async -> ATTrackingManager.AuthorizationStatus {
        guard !hasRequestedATT else {
            print("📊 [AppsFlyer] ATT already requested, current status: \(attStatus.rawValue)")
            return attStatus
        }
        
        // ATT доступен только с iOS 14
        guard #available(iOS 14, *) else {
            print("📊 [AppsFlyer] ATT not available on this iOS version")
            hasRequestedATT = true
            attStatus = .authorized
            return .authorized
        }
        
        // Проверяем текущий статус
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        if currentStatus != .notDetermined {
            print("📊 [AppsFlyer] ATT already determined: \(currentStatus.rawValue)")
            hasRequestedATT = true
            attStatus = currentStatus
            return currentStatus
        }
        
        print("📊 [AppsFlyer] Requesting ATT permission...")
        
        return await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.hasRequestedATT = true
                    self?.attStatus = status
                    
                    switch status {
                    case .authorized:
                        print("📊 [AppsFlyer] ATT Status: Authorized ✅")
                        // IDFA теперь доступен - обновляем идентификаторы в Apphud
                        self?.setDeviceIdentifiersToApphud()
                    case .denied:
                        print("📊 [AppsFlyer] ATT Status: Denied ❌")
                    case .restricted:
                        print("📊 [AppsFlyer] ATT Status: Restricted ⚠️")
                    case .notDetermined:
                        print("📊 [AppsFlyer] ATT Status: Not Determined")
                    @unknown default:
                        print("📊 [AppsFlyer] ATT Status: Unknown")
                    }
                    
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    /// Проверяет текущий статус ATT без запроса
    func checkATTStatus() -> ATTrackingManager.AuthorizationStatus {
        guard #available(iOS 14, *) else {
            return .authorized
        }
        return ATTrackingManager.trackingAuthorizationStatus
    }
    
    // MARK: - SDK Start
    
    /// Запускает AppsFlyer SDK (вызывается автоматически при активации приложения)
    @objc private func didBecomeActive() {
        guard isConfigured else {
            print("📊 [AppsFlyer] Not configured yet, skipping start")
            return
        }
        
        AppsFlyerLib.shared().start()
        print("📊 [AppsFlyer] SDK Started")
    }
    
    /// Принудительный запуск SDK (если нужно запустить вручную)
    func start() {
        guard isConfigured else {
            print("📊 [AppsFlyer] Cannot start - not configured")
            return
        }
        
        AppsFlyerLib.shared().start()
        print("📊 [AppsFlyer] SDK Started manually")
    }
    
    // MARK: - In-App Events
    
    /// Логирует custom событие в AppsFlyer
    func logEvent(name: String, values: [String: Any]? = nil) {
        AppsFlyerLib.shared().logEvent(name, withValues: values)
        print("📊 [AppsFlyer] Event logged: \(name)")
    }
    
    /// Логирует событие покупки
    func logPurchase(productId: String, price: Double, currency: String) {
        let values: [String: Any] = [
            AFEventParamContentId: productId,
            AFEventParamRevenue: price,
            AFEventParamCurrency: currency
        ]
        AppsFlyerLib.shared().logEvent(AFEventPurchase, withValues: values)
        print("📊 [AppsFlyer] Purchase logged: \(productId), \(price) \(currency)")
    }
    
    // MARK: - User Properties
    
    /// Устанавливает Customer User ID
    func setCustomerUserID(_ userID: String) {
        AppsFlyerLib.shared().customerUserID = userID
        print("📊 [AppsFlyer] Customer User ID updated: \(userID)")
    }
    
    /// Получает AppsFlyer UID
    func getAppsFlyerUID() -> String {
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }
}

// MARK: - AppsFlyerLibDelegate

extension AppsFlyerService: AppsFlyerLibDelegate {
    
    /// Вызывается при успешном получении conversion data
    nonisolated func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        print("📊 [AppsFlyer] Conversion data received successfully")
        
        // Получаем AppsFlyer UID
        let appsFlyerUID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        // Передаем данные атрибуции в Apphud согласно документации:
        // https://docs.apphud.com/docs/appsflyer#pass-attribution-data-to-apphud-required
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: conversionInfo),
            from: .appsFlyer,
            identifer: appsFlyerUID,
            callback: nil
        )
        print("📊 [AppsFlyer] Attribution sent to Apphud with UID: \(appsFlyerUID)")
        
        // Логируем данные атрибуции для отладки
        if let status = conversionInfo["af_status"] as? String {
            print("📊 [AppsFlyer] Install type: \(status)")
            
            if status == "Non-organic" {
                if let mediaSource = conversionInfo["media_source"] {
                    print("📊 [AppsFlyer] Media Source: \(mediaSource)")
                }
                if let campaign = conversionInfo["campaign"] {
                    print("📊 [AppsFlyer] Campaign: \(campaign)")
                }
                if let adSet = conversionInfo["adset"] {
                    print("📊 [AppsFlyer] Ad Set: \(adSet)")
                }
                if let ad = conversionInfo["ad"] {
                    print("📊 [AppsFlyer] Ad: \(ad)")
                }
            }
        }
        
        // Логируем полные данные в debug
        #if DEBUG
        print("📊 [AppsFlyer] Full conversion data:")
        for (key, value) in conversionInfo {
            print("   \(key): \(value)")
        }
        #endif
    }
    
    /// Вызывается при ошибке получения conversion data
    nonisolated func onConversionDataFail(_ error: Error) {
        print("📊 [AppsFlyer] Conversion data failed: \(error.localizedDescription)")
        
        // Все равно передаем атрибуцию в Apphud с информацией об ошибке
        // согласно документации: https://docs.apphud.com/docs/appsflyer
        let appsFlyerUID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: ["error": error.localizedDescription]),
            from: .appsFlyer,
            identifer: appsFlyerUID,
            callback: nil
        )
        print("📊 [AppsFlyer] Attribution (with error) sent to Apphud")
    }
    
    /// Вызывается при открытии приложения через direct deep link
    nonisolated func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        print("📊 [AppsFlyer] App opened via attribution link")
        
        #if DEBUG
        for (key, value) in attributionData {
            print("   \(key): \(value)")
        }
        #endif
    }
    
    /// Вызывается при ошибке deep link атрибуции
    nonisolated func onAppOpenAttributionFailure(_ error: Error) {
        print("📊 [AppsFlyer] App open attribution failed: \(error.localizedDescription)")
    }
}

// MARK: - ATT Status Extension

extension ATTrackingManager.AuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
}
