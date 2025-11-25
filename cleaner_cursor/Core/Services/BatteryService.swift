import Foundation
import UIKit

// MARK: - Battery Service
/// Сервис для мониторинга батареи

@MainActor
final class BatteryService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var batteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isLowPowerModeEnabled: Bool = false
    
    // MARK: - Singleton
    
    static let shared = BatteryService()
    
    // MARK: - Init
    
    private init() {
        setupBatteryMonitoring()
        updateBatteryInfo()
    }
    
    // MARK: - Setup
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerModeDidChange),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    // MARK: - Update Methods
    
    @objc private func batteryLevelDidChange() {
        updateBatteryInfo()
    }
    
    @objc private func batteryStateDidChange() {
        updateBatteryInfo()
    }
    
    @objc private func powerModeDidChange() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    // MARK: - Computed Properties
    
    var batteryPercentage: Int {
        Int(batteryLevel * 100)
    }
    
    var isCharging: Bool {
        batteryState == .charging || batteryState == .full
    }
    
    var isFull: Bool {
        batteryState == .full
    }
    
    var batteryStateDescription: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
    
    var batteryHealthStatus: BatteryHealthStatus {
        if batteryLevel >= 0.8 {
            return .excellent
        } else if batteryLevel >= 0.5 {
            return .good
        } else if batteryLevel >= 0.2 {
            return .fair
        } else {
            return .low
        }
    }
    
    // MARK: - Battery Tips
    
    var batteryTips: [BatteryTip] {
        var tips: [BatteryTip] = []
        
        // Always show general tips
        tips.append(BatteryTip(
            icon: "sun.max.fill",
            title: "Reduce Screen Brightness",
            description: "Lower brightness can significantly extend battery life"
        ))
        
        tips.append(BatteryTip(
            icon: "wifi",
            title: "Turn Off Wi-Fi When Not Needed",
            description: "Disable Wi-Fi if you're not using it to save power"
        ))
        
        tips.append(BatteryTip(
            icon: "location.fill",
            title: "Limit Location Services",
            description: "Restrict background location access for apps"
        ))
        
        if !isLowPowerModeEnabled && batteryLevel < 0.3 {
            tips.insert(BatteryTip(
                icon: "battery.25",
                title: "Enable Low Power Mode",
                description: "Extend battery life by reducing background activity"
            ), at: 0)
        }
        
        tips.append(BatteryTip(
            icon: "app.badge",
            title: "Disable Background App Refresh",
            description: "Stop apps from refreshing in the background"
        ))
        
        tips.append(BatteryTip(
            icon: "envelope.fill",
            title: "Fetch Mail Less Frequently",
            description: "Change mail fetch to manual or hourly intervals"
        ))
        
        return tips
    }
}

// MARK: - Battery Health Status

enum BatteryHealthStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .excellent: return AppColors.statusSuccess
        case .good: return AppColors.accentBlue
        case .fair: return AppColors.statusWarning
        case .low: return AppColors.statusError
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "battery.100"
        case .good: return "battery.75"
        case .fair: return "battery.50"
        case .low: return "battery.25"
        }
    }
}

// MARK: - Battery Tip Model

struct BatteryTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

import SwiftUI

