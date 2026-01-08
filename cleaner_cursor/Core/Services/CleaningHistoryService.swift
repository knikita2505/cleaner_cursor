import Foundation
import SwiftUI

// MARK: - Cleaning History Service
/// Сервис для хранения и управления историей очисток

@MainActor
final class CleaningHistoryService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CleaningHistoryService()
    
    // MARK: - Published Properties
    
    @Published private(set) var records: [CleaningRecord] = []
    @Published private(set) var todaySummary: CleaningSummary = .empty
    @Published private(set) var weeklySummary: CleaningSummary = .empty
    @Published private(set) var monthlySummary: CleaningSummary = .empty
    @Published private(set) var weeklyData: [DailyCleaningData] = []
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let recordsKey = "cleaning_history_records"
    private let calendar = Calendar.current
    
    // MARK: - Init
    
    private init() {
        loadRecords()
        calculateSummaries()
    }
    
    // MARK: - Public Methods
    
    /// Очистить всю историю
    func clearAllHistory() {
        records.removeAll()
        userDefaults.removeObject(forKey: recordsKey)
        calculateSummaries()
    }
    
    /// Записать операцию очистки
    func recordCleaning(type: CleaningType, itemsCount: Int, bytesFreed: Int64) {
        let record = CleaningRecord(
            id: UUID().uuidString,
            date: Date(),
            type: type,
            itemsCount: itemsCount,
            bytesFreed: bytesFreed
        )
        
        records.insert(record, at: 0)
        saveRecords()
        calculateSummaries()
    }
    
    /// Получить данные для pie chart по типам
    func getPieChartData() -> [PieChartSegment] {
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let monthRecords = records.filter { $0.date >= monthAgo }
        
        var byType: [CleaningType: Int64] = [:]
        for record in monthRecords {
            byType[record.type, default: 0] += record.bytesFreed
        }
        
        let total = byType.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return byType.map { type, bytes in
            PieChartSegment(
                type: type,
                bytes: bytes,
                percentage: Double(bytes) / Double(total)
            )
        }.sorted { $0.bytes > $1.bytes }
    }
    
    /// Получить динамические рекомендации
    func getRecommendations() -> [CleaningRecommendation] {
        var recommendations: [CleaningRecommendation] = []
        
        // Анализируем историю и текущие данные
        let photoService = PhotoService.shared
        let videoService = VideoService.shared
        
        // Скриншоты
        let screenshotsCount = photoService.screenshotsCount
        if screenshotsCount > 10 {
            recommendations.append(CleaningRecommendation(
                icon: "camera.viewfinder",
                title: "Clean Screenshots",
                description: "You have \(screenshotsCount) screenshots that might be outdated",
                type: .screenshots,
                priority: screenshotsCount > 50 ? .high : .medium
            ))
        }
        
        // Похожие фото
        let similarCount = photoService.similarCount
        if similarCount > 5 {
            recommendations.append(CleaningRecommendation(
                icon: "photo.on.rectangle.angled",
                title: "Similar Photos Found",
                description: "\(similarCount) similar photos can be removed",
                type: .similarPhotos,
                priority: similarCount > 20 ? .high : .medium
            ))
        }
        
        // Дубликаты
        let duplicatesCount = photoService.duplicatesCount
        if duplicatesCount > 0 {
            recommendations.append(CleaningRecommendation(
                icon: "plus.square.on.square",
                title: "Duplicates Detected",
                description: "\(duplicatesCount) duplicate photos taking extra space",
                type: .duplicates,
                priority: .high
            ))
        }
        
        // Видео
        let totalVideosCount = videoService.totalVideosCount
        if totalVideosCount > 10 {
            recommendations.append(CleaningRecommendation(
                icon: "video.fill",
                title: "Review Videos",
                description: "\(totalVideosCount) videos to review",
                type: .videos,
                priority: .medium
            ))
        }
        
        // Live Photos
        let livePhotosCount = photoService.livePhotosCount
        if livePhotosCount > 20 {
            recommendations.append(CleaningRecommendation(
                icon: "livephoto",
                title: "Convert Live Photos",
                description: "\(livePhotosCount) Live Photos can be converted to save space",
                type: .livePhotos,
                priority: .low
            ))
        }
        
        // Если ничего не нашли, показываем общую рекомендацию
        if recommendations.isEmpty {
            recommendations.append(CleaningRecommendation(
                icon: "checkmark.circle.fill",
                title: "Looking Good!",
                description: "Your device is well optimized. Keep it up!",
                type: nil,
                priority: .low
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Private Methods
    
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: recordsKey),
              let decoded = try? JSONDecoder().decode([CleaningRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }
    
    private func saveRecords() {
        // Храним только последние 6 месяцев
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        records = records.filter { $0.date >= sixMonthsAgo }
        
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }
    
    private func calculateSummaries() {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        // Today
        let todayRecords = records.filter { $0.date >= startOfToday }
        todaySummary = calculateSummary(from: todayRecords)
        
        // Week
        let weekRecords = records.filter { $0.date >= startOfWeek }
        weeklySummary = calculateSummary(from: weekRecords)
        
        // Month
        let monthRecords = records.filter { $0.date >= startOfMonth }
        monthlySummary = calculateSummary(from: monthRecords)
        
        // Weekly data for graph
        calculateWeeklyData()
    }
    
    private func calculateSummary(from records: [CleaningRecord]) -> CleaningSummary {
        let totalItems = records.reduce(0) { $0 + $1.itemsCount }
        let totalBytes = records.reduce(Int64(0)) { $0 + $1.bytesFreed }
        let sessionsCount = Set(records.map { calendar.startOfDay(for: $0.date) }).count
        
        return CleaningSummary(
            itemsCount: totalItems,
            bytesFreed: totalBytes,
            sessionsCount: sessionsCount
        )
    }
    
    private func calculateWeeklyData() {
        var data: [DailyCleaningData] = []
        let now = Date()
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let dayRecords = records.filter { $0.date >= startOfDay && $0.date < endOfDay }
            let totalBytes = dayRecords.reduce(Int64(0)) { $0 + $1.bytesFreed }
            
            let weekday = calendar.component(.weekday, from: date)
            let dayName = calendar.shortWeekdaySymbols[weekday - 1]
            
            data.append(DailyCleaningData(
                date: date,
                dayName: dayName,
                bytesFreed: totalBytes
            ))
        }
        
        weeklyData = data
    }
}

// MARK: - Models

struct CleaningRecord: Codable, Identifiable {
    let id: String
    let date: Date
    let type: CleaningType
    let itemsCount: Int
    let bytesFreed: Int64
}

enum CleaningType: String, Codable, CaseIterable {
    case screenshots
    case similarPhotos
    case duplicates
    case livePhotos
    case burstPhotos
    case videos
    case shortVideos
    case contacts
    case swipePhotos
    case bigFiles
    
    var displayName: String {
        switch self {
        case .screenshots: return "Screenshots"
        case .similarPhotos: return "Similar Photos"
        case .duplicates: return "Duplicates"
        case .livePhotos: return "Live Photos"
        case .burstPhotos: return "Burst Photos"
        case .videos: return "Videos"
        case .shortVideos: return "Short Videos"
        case .contacts: return "Contacts"
        case .swipePhotos: return "Swipe Clean"
        case .bigFiles: return "Big Files"
        }
    }
    
    var icon: String {
        switch self {
        case .screenshots: return "camera.viewfinder"
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .duplicates: return "plus.square.on.square"
        case .livePhotos: return "livephoto"
        case .burstPhotos: return "square.stack.3d.down.right"
        case .videos: return "video.fill"
        case .shortVideos: return "video.badge.ellipsis"
        case .contacts: return "person.crop.circle"
        case .swipePhotos: return "hand.draw"
        case .bigFiles: return "doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .screenshots: return AppColors.accentBlue
        case .similarPhotos: return AppColors.accentPurple
        case .duplicates: return AppColors.statusError
        case .livePhotos: return AppColors.statusWarning
        case .burstPhotos: return AppColors.accentLilac
        case .videos: return AppColors.statusSuccess
        case .shortVideos: return AppColors.accentBlue
        case .contacts: return AppColors.accentPurple
        case .swipePhotos: return AppColors.neonPink
        case .bigFiles: return AppColors.statusWarning
        }
    }
}

struct CleaningSummary {
    let itemsCount: Int
    let bytesFreed: Int64
    let sessionsCount: Int
    
    static let empty = CleaningSummary(itemsCount: 0, bytesFreed: 0, sessionsCount: 0)
    
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
    }
}

struct DailyCleaningData: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let bytesFreed: Int64
    
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: bytesFreed, countStyle: .file)
    }
}

struct PieChartSegment: Identifiable {
    let id = UUID()
    let type: CleaningType
    let bytes: Int64
    let percentage: Double
    
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct CleaningRecommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let type: CleaningType?
    let priority: RecommendationPriority
}

enum RecommendationPriority: Int {
    case low = 0
    case medium = 1
    case high = 2
    
    var color: Color {
        switch self {
        case .low: return AppColors.textTertiary
        case .medium: return AppColors.statusWarning
        case .high: return AppColors.statusError
        }
    }
}

