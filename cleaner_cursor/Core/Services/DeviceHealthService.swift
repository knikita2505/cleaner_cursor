import Foundation
import UIKit
import SwiftUI

// MARK: - Device Health Service
/// Сервис для оценки общего состояния устройства

@MainActor
final class DeviceHealthService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DeviceHealthService()
    
    // MARK: - Published Properties
    
    @Published var healthScore: Int = 0
    @Published var storageScore: Int = 0
    @Published var batteryScore: Int = 0
    @Published var performanceScore: Int = 0
    @Published var temperatureScore: Int = 0
    
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var systemUptime: TimeInterval = 0
    
    // MARK: - Dependencies
    
    private let batteryService = BatteryService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    
    private init() {
        setupObservers()
        refresh()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe thermal state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func thermalStateDidChange() {
        thermalState = ProcessInfo.processInfo.thermalState
        calculateScores()
    }
    
    // MARK: - Public Methods
    
    func refresh() {
        thermalState = ProcessInfo.processInfo.thermalState
        systemUptime = ProcessInfo.processInfo.systemUptime
        calculateScores()
    }
    
    // MARK: - Score Calculation
    
    private func calculateScores() {
        // Storage Score (0-100)
        storageScore = calculateStorageScore()
        
        // Battery Score (0-100)
        batteryScore = calculateBatteryScore()
        
        // Performance Score (0-100)
        performanceScore = calculatePerformanceScore()
        
        // Temperature Score (0-100)
        temperatureScore = calculateTemperatureScore()
        
        // Overall Health Score = average of all scores
        let scores = [storageScore, batteryScore, performanceScore, temperatureScore]
        healthScore = scores.reduce(0, +) / scores.count
    }
    
    private func calculateStorageScore() -> Int {
        let usedPercentage = (storageService.storageInfo?.usagePercentage ?? 0) * 100
        
        // 0-50% used = 100 score
        // 50-75% used = 75-100 score
        // 75-90% used = 50-75 score
        // 90-100% used = 0-50 score
        
        if usedPercentage <= 50 {
            return 100
        } else if usedPercentage <= 75 {
            return Int(100 - (usedPercentage - 50) * 1.0)
        } else if usedPercentage <= 90 {
            return Int(75 - (usedPercentage - 75) * 1.67)
        } else {
            return max(0, Int(50 - (usedPercentage - 90) * 5.0))
        }
    }
    
    var usedPercentage: Double {
        (storageService.storageInfo?.usagePercentage ?? 0) * 100
    }
    
    private func calculateBatteryScore() -> Int {
        // Battery score based on current level
        let level = batteryService.batteryLevel
        
        // If charging or full, give bonus
        if batteryService.isCharging {
            return min(100, Int(level * 100) + 10)
        }
        
        return Int(level * 100)
    }
    
    private func calculatePerformanceScore() -> Int {
        // Based on uptime - devices perform better after restart
        let uptimeHours = systemUptime / 3600
        
        // Fresh restart (< 1 day) = 100
        // 1-3 days = 90
        // 3-7 days = 80
        // 7-14 days = 70
        // 14+ days = 60
        
        if uptimeHours < 24 {
            return 100
        } else if uptimeHours < 72 {
            return 90
        } else if uptimeHours < 168 {
            return 80
        } else if uptimeHours < 336 {
            return 70
        } else {
            return 60
        }
    }
    
    private func calculateTemperatureScore() -> Int {
        switch thermalState {
        case .nominal:
            return 100
        case .fair:
            return 75
        case .serious:
            return 40
        case .critical:
            return 10
        @unknown default:
            return 80
        }
    }
    
    // MARK: - Status Helpers
    
    var healthStatus: HealthStatus {
        if healthScore >= 80 {
            return .excellent
        } else if healthScore >= 60 {
            return .good
        } else if healthScore >= 40 {
            return .needsAttention
        } else {
            return .critical
        }
    }
    
    var storageStatus: CategoryStatus {
        if storageScore >= 75 {
            return .good
        } else if storageScore >= 50 {
            return .fair
        } else {
            return .needsAttention
        }
    }
    
    var batteryStatus: CategoryStatus {
        if batteryScore >= 50 {
            return .good
        } else if batteryScore >= 20 {
            return .fair
        } else {
            return .needsAttention
        }
    }
    
    var performanceStatus: CategoryStatus {
        if performanceScore >= 80 {
            return .good
        } else if performanceScore >= 60 {
            return .fair
        } else {
            return .needsAttention
        }
    }
    
    var temperatureStatus: CategoryStatus {
        if temperatureScore >= 75 {
            return .good
        } else if temperatureScore >= 40 {
            return .fair
        } else {
            return .needsAttention
        }
    }
    
    var thermalStateDescription: String {
        switch thermalState {
        case .nominal:
            return "Normal"
        case .fair:
            return "Slightly Elevated"
        case .serious:
            return "High"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
    
    var uptimeDescription: String {
        let hours = Int(systemUptime / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

// MARK: - Health Status

enum HealthStatus {
    case excellent
    case good
    case needsAttention
    case critical
    
    var title: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .needsAttention: return "Needs Attention"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return AppColors.statusSuccess
        case .good: return AppColors.accentBlue
        case .needsAttention: return AppColors.statusWarning
        case .critical: return AppColors.statusError
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.shield.fill"
        case .good: return "shield.fill"
        case .needsAttention: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        }
    }
}

// MARK: - Category Status

enum CategoryStatus {
    case good
    case fair
    case needsAttention
    
    var title: String {
        switch self {
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsAttention: return "Needs Attention"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return AppColors.statusSuccess
        case .fair: return AppColors.statusWarning
        case .needsAttention: return AppColors.statusError
        }
    }
}
