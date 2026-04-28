import Foundation
import AppMetricaCore
import AppMetricaAdSupport
import ApphudSDK

// MARK: - AppMetrica Service

@MainActor
final class AppMetricaService {
    
    // MARK: - Singleton
    
    static let shared = AppMetricaService()
    
    // MARK: - Configuration
    
    /// AppMetrica API Key (из дашборда AppMetrica)
    private let apiKey = "54cd1d31-6ce5-4254-8ba6-1e632e72c367"
    
    // MARK: - Private Properties
    
    private var isActivated = false
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Activation
    
    /// Активирует AppMetrica SDK и связывает идентификаторы с Apphud.
    /// Вызывать в App.init() после Apphud.start()
    func activate() {
        guard !isActivated else {
            print("📈 [AppMetrica] Already activated")
            return
        }
        
        let configuration = AppMetricaConfiguration(apiKey: apiKey)!
        
        // Передаём Apphud User ID как userProfileID для связки
        let apphudUserID = Apphud.userID()
        configuration.userProfileID = apphudUserID
        
        AppMetrica.activate(with: configuration)
        isActivated = true
        
        print("📈 [AppMetrica] Activated with userProfileID: \(apphudUserID)")
        
        // Передаём AppMetrica device_id в Apphud для серверной интеграции
        sendDeviceIdToApphud()
    }
    
    // MARK: - Apphud Integration
    
    /// Передаёт AppMetrica device_id в Apphud,
    /// чтобы Apphud мог отправлять конверсии в AppMetrica
    private func sendDeviceIdToApphud() {
        AppMetrica.requestStartupIdentifiers(
            for: [.deviceIDKey],
            on: .main
        ) { identifiers, error in
            if let error = error {
                print("📈 [AppMetrica] Failed to get device_id: \(error.localizedDescription)")
                return
            }
            
            guard let deviceID = identifiers?[.deviceIDKey] as? String else {
                print("📈 [AppMetrica] device_id is nil")
                return
            }
            
            print("📈 [AppMetrica] device_id: \(deviceID)")
            
            Apphud.setAttribution(
                data: ApphudAttributionData(rawData: ["appmetrica_device_id": deviceID]),
                from: .custom,
                identifer: deviceID,
                callback: nil
            )
            
            print("📈 [AppMetrica] device_id sent to Apphud")
        }
    }
}
