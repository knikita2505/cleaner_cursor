import Foundation
import Photos

// MARK: - Swipe Progress Service
/// Сервис для хранения прогресса свайп-сессий

final class SwipeProgressService: ObservableObject {
    
    static let shared = SwipeProgressService()
    
    // MARK: - Published Properties
    
    @Published private(set) var monthProgress: [String: MonthProgress] = [:]
    
    // MARK: - Private
    
    private let defaults = UserDefaults.standard
    private let progressKey = "swipe_month_progress"
    
    // MARK: - Init
    
    private init() {
        loadProgress()
    }
    
    // MARK: - Public Methods
    
    /// Получить прогресс для месяца
    func getProgress(for monthKey: String) -> MonthProgress {
        monthProgress[monthKey] ?? MonthProgress(monthKey: monthKey, reviewedCount: 0, totalCount: 0, deletedIds: [], keptIds: [])
    }
    
    /// Обновить прогресс после решения
    func updateProgress(monthKey: String, photoId: String, decision: SwipeDecision) {
        var progress = getProgress(for: monthKey)
        
        switch decision {
        case .keep:
            if !progress.keptIds.contains(photoId) {
                progress.keptIds.append(photoId)
                progress.reviewedCount += 1
            }
        case .delete:
            if !progress.deletedIds.contains(photoId) {
                progress.deletedIds.append(photoId)
                progress.reviewedCount += 1
            }
        }
        
        monthProgress[monthKey] = progress
        saveProgress()
    }
    
    /// Установить общее количество фото в месяце (только если ещё не установлено)
    func setTotalCount(monthKey: String, total: Int) {
        var progress = getProgress(for: monthKey)
        
        // Don't update if already set - preserves original count after deletions
        if progress.totalCount > 0 {
            return
        }
        
        progress.totalCount = total
        monthProgress[monthKey] = progress
        saveProgress()
    }
    
    /// Принудительно обновить общее количество фото (например, при первой инициализации)
    func forceSetTotalCount(monthKey: String, total: Int) {
        var progress = getProgress(for: monthKey)
        progress.totalCount = total
        monthProgress[monthKey] = progress
        saveProgress()
    }
    
    /// Сбросить прогресс для месяца
    func resetProgress(for monthKey: String) {
        monthProgress[monthKey] = nil
        saveProgress()
    }
    
    /// Отменить последнее решение
    func undoLastDecision(monthKey: String) -> String? {
        guard var progress = monthProgress[monthKey] else { return nil }
        
        // Сначала проверяем deletedIds (они более важные для отмены)
        if let lastDeleted = progress.deletedIds.popLast() {
            progress.reviewedCount = max(0, progress.reviewedCount - 1)
            monthProgress[monthKey] = progress
            saveProgress()
            return lastDeleted
        }
        
        if let lastKept = progress.keptIds.popLast() {
            progress.reviewedCount = max(0, progress.reviewedCount - 1)
            monthProgress[monthKey] = progress
            saveProgress()
            return lastKept
        }
        
        return nil
    }
    
    /// Очистить deleted IDs после реального удаления
    func clearDeletedIds(monthKey: String) {
        guard var progress = monthProgress[monthKey] else { return }
        progress.deletedIds = []
        monthProgress[monthKey] = progress
        saveProgress()
    }
    
    /// Проверить, было ли фото уже просмотрено
    func isPhotoReviewed(monthKey: String, photoId: String) -> Bool {
        let progress = getProgress(for: monthKey)
        return progress.deletedIds.contains(photoId) || progress.keptIds.contains(photoId)
    }
    
    /// Получить общий процент прогресса
    func getTotalProgress() -> Double {
        let totalReviewed = monthProgress.values.reduce(0) { $0 + $1.reviewedCount }
        let totalPhotos = monthProgress.values.reduce(0) { $0 + $1.totalCount }
        
        guard totalPhotos > 0 else { return 0 }
        return Double(totalReviewed) / Double(totalPhotos) * 100
    }
    
    /// Количество месяцев в очереди (не до конца просмотренных)
    func getMonthsInQueue() -> Int {
        monthProgress.values.filter { $0.reviewedCount < $0.totalCount && $0.totalCount > 0 }.count
    }
    
    // MARK: - Private Methods
    
    private func loadProgress() {
        guard let data = defaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: MonthProgress].self, from: data) else {
            return
        }
        monthProgress = decoded
    }
    
    private func saveProgress() {
        guard let encoded = try? JSONEncoder().encode(monthProgress) else { return }
        defaults.set(encoded, forKey: progressKey)
    }
}

// MARK: - Models

struct MonthProgress: Codable, Identifiable {
    var id: String { monthKey }
    let monthKey: String
    var reviewedCount: Int
    var totalCount: Int
    var deletedIds: [String]
    var keptIds: [String]
    
    var progressPercent: Double {
        guard totalCount > 0 else { return 0 }
        return Double(reviewedCount) / Double(totalCount) * 100
    }
    
    var isCompleted: Bool {
        totalCount > 0 && reviewedCount >= totalCount
    }
    
    var remainingCount: Int {
        max(0, totalCount - reviewedCount)
    }
}

enum SwipeDecision {
    case keep
    case delete
}

// MARK: - Month Group Model

struct PhotoMonthGroup: Identifiable, Hashable {
    let id: String
    let month: Date
    let photos: [PhotoAsset]
    
    var monthKey: String { id }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    var shortDisplayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoMonthGroup, rhs: PhotoMonthGroup) -> Bool {
        lhs.id == rhs.id
    }
}
