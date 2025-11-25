import Foundation

// MARK: - Storage Service
/// Сервис для анализа хранилища устройства

@MainActor
final class StorageService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var storageInfo: StorageInfo?
    @Published var isLoading: Bool = false
    
    // MARK: - Singleton
    
    static let shared = StorageService()
    
    // MARK: - Init
    
    private init() {
        Task {
            await refreshStorageInfo()
        }
    }
    
    // MARK: - Storage Info
    
    func refreshStorageInfo() async {
        isLoading = true
        
        let info = await Task.detached(priority: .userInitiated) {
            self.calculateStorageInfo()
        }.value
        
        storageInfo = info
        isLoading = false
    }
    
    nonisolated private func calculateStorageInfo() -> StorageInfo? {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSpace = attributes[.systemSize] as? Int64,
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return nil
        }
        
        let usedSpace = totalSpace - freeSpace
        
        return StorageInfo(
            totalSpace: totalSpace,
            usedSpace: usedSpace,
            freeSpace: freeSpace
        )
    }
    
    // MARK: - Format Helpers
    
    nonisolated static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    nonisolated static func formatBytesShort(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Storage Info Model

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64
    
    var usagePercentage: Double {
        Double(usedSpace) / Double(totalSpace)
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    
    var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
}

// MARK: - Storage Category

enum StorageCategory: String, CaseIterable, Identifiable {
    case photos = "Photos"
    case videos = "Videos"
    case apps = "Apps"
    case system = "System"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .photos: return "photo.fill"
        case .videos: return "video.fill"
        case .apps: return "square.grid.2x2.fill"
        case .system: return "gear"
        case .other: return "doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .photos: return AppColors.accentBlue
        case .videos: return AppColors.accentPurple
        case .apps: return AppColors.statusSuccess
        case .system: return AppColors.textTertiary
        case .other: return AppColors.statusWarning
        }
    }
}

import SwiftUI

