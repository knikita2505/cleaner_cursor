import SwiftUI
import Photos
import Combine

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DashboardViewModel()
    
    // MARK: - Published Properties
    
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = ""
    
    // Storage Stats (анимируемые)
    @Published var spaceToClean: Int64 = 0
    @Published var clutterSize: Int64 = 0
    @Published var appsDataSize: Int64 = 0
    @Published var totalStorageUsed: Int64 = 0
    @Published var totalStorage: Int64 = 0
    
    // Categories
    @Published var categories: [MediaCategory] = []
    
    // Scan state
    @Published var hasScannedOnce: Bool = false
    
    // MARK: - Private
    
    private var scanTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var lastScanTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 минут
    
    // MARK: - Services
    
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    
    private init() {
        setupCategories()
        observePhotoServiceCache()
    }
    
    private func setupCategories() {
        // Порядок согласно requirements/4_dashboard.md + Blurred
        categories = [
            MediaCategory(id: "duplicates", title: "Duplicate photos", icon: "square.on.square", color: AppColors.statusError, countsTowardsCleanup: true),
            MediaCategory(id: "similar", title: "Similar photos", icon: "square.stack.3d.down.right", color: AppColors.accentPurple, countsTowardsCleanup: true),
            MediaCategory(id: "blurred", title: "Blurred", icon: "camera.metering.unknown", color: Color(hex: "9CA3AF"), countsTowardsCleanup: true),
            MediaCategory(id: "screenshots", title: "Screenshots", icon: "camera.viewfinder", color: AppColors.accentBlue, countsTowardsCleanup: true),
            MediaCategory(id: "live_photos", title: "Live Photos", icon: "livephoto", color: AppColors.statusWarning, countsTowardsCleanup: true),
            MediaCategory(id: "videos", title: "Videos", icon: "video.fill", color: AppColors.statusSuccess, countsTowardsCleanup: false),
            MediaCategory(id: "short_videos", title: "Short videos", icon: "bolt.fill", color: AppColors.accentBlue.opacity(0.8), countsTowardsCleanup: false),
            MediaCategory(id: "screen_recordings", title: "Screen recordings", icon: "record.circle", color: AppColors.statusError.opacity(0.8), countsTowardsCleanup: false)
        ]
    }
    
    // MARK: - Observe PhotoService Cache
    
    private func observePhotoServiceCache() {
        // Наблюдаем за кешем дубликатов
        photoService.$cachedDuplicates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                guard let self = self, !groups.isEmpty else { return }
                let count = groups.reduce(0) { $0 + $1.assets.count }
                let size = groups.reduce(Int64(0)) { $0 + $1.savingsSize }
                self.animateUpdateCategory(id: "duplicates", count: count, size: size)
                self.loadThumbnailForDuplicates(groups: groups)
            }
            .store(in: &cancellables)
        
        // Наблюдаем за кешем похожих фото
        photoService.$cachedSimilarPhotos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                guard let self = self, !groups.isEmpty else { return }
                let count = groups.reduce(0) { $0 + max(0, $1.assets.count - 1) }
                let size = groups.reduce(Int64(0)) { $0 + $1.savingsSize }
                self.animateUpdateCategory(id: "similar", count: count, size: size)
                self.loadThumbnailForSimilar(groups: groups)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Start Scan (вызывается ПОСЛЕ появления UI)
    
    func startScanIfNeeded() {
        guard photoService.isAuthorized else { return }
        
        // Проверяем кеш
        if let lastScan = lastScanTime,
           Date().timeIntervalSince(lastScan) < cacheValidityDuration,
           hasScannedOnce {
            // Кеш валиден, просто обновляем UI
            return
        }
        
        startBackgroundScan()
    }
    
    func forceRefresh() {
        photoService.invalidateCache()
        lastScanTime = nil
        startBackgroundScan()
    }
    
    // MARK: - Background Scan (не блокирует UI)
    
    private func startBackgroundScan() {
        scanTask?.cancel()
        
        isScanning = true
        scanProgress = "Starting..."
        
        scanTask = Task(priority: .utility) {
            await performBackgroundScan()
        }
    }
    
    private func performBackgroundScan() async {
        // 1. Storage info (быстро)
        await updateStorageInfo()
        
        // 2. ВСЕ категории параллельно!
        await MainActor.run { scanProgress = "Scanning media..." }
        
        await withTaskGroup(of: Void.self) { group in
            // Быстрые категории (системные папки)
            group.addTask { await self.scanScreenshotsBackground() }
            group.addTask { await self.scanLivePhotosBackground() }
            group.addTask { await self.scanVideosBackground() }
            group.addTask { await self.scanShortVideosBackground() }
            group.addTask { await self.scanScreenRecordingsBackground() }
            
            // Тяжёлые категории (тоже параллельно!)
            group.addTask { await self.scanDuplicatesBackground() }
            group.addTask { await self.scanSimilarBackground() }
            group.addTask { await self.scanBlurredBackground() }
        }
        
        // Завершено
        await MainActor.run {
            self.isScanning = false
            self.scanProgress = ""
            self.hasScannedOnce = true
            self.lastScanTime = Date()
        }
    }
    
    // MARK: - Blurred Photos
    
    private func scanBlurredBackground() async {
        await MainActor.run { scanProgress = "Finding blurred photos..." }
        
        let (photos, thumbnail) = await Task.detached(priority: .utility) {
            let blurred = self.photoService.findBlurredPhotos(limit: 300)
            let firstAsset = blurred.first?.asset
            return (blurred, firstAsset)
        }.value
        
        let totalSize = photos.reduce(Int64(0)) { $0 + $1.fileSize }
        
        await MainActor.run {
            animateUpdateCategory(id: "blurred", count: photos.count, size: totalSize)
            if let asset = thumbnail {
                loadThumbnail(for: "blurred", asset: asset)
            }
        }
    }
    
    private func scanScreenshotsBackground() async {
        let (count, size, thumbnail) = await Task.detached(priority: .utility) {
            let fetchResult = self.photoService.fetchScreenshots()
            let count = fetchResult.count
            var totalSize: Int64 = 0
            var firstAsset: PHAsset?
            
            fetchResult.enumerateObjects { asset, index, _ in
                if index == 0 { firstAsset = asset }
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first,
                   let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
            
            return (count, totalSize, firstAsset)
        }.value
        
        await MainActor.run {
            animateUpdateCategory(id: "screenshots", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "screenshots", asset: asset)
            }
        }
    }
    
    private func scanLivePhotosBackground() async {
        let (count, size, thumbnail) = await Task.detached(priority: .utility) {
            let fetchResult = self.photoService.fetchLivePhotos()
            let count = fetchResult.count
            var totalSize: Int64 = 0
            var firstAsset: PHAsset?
            
            fetchResult.enumerateObjects { asset, index, _ in
                if index == 0 { firstAsset = asset }
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if let size = resource.value(forKey: "fileSize") as? Int64 {
                        totalSize += size
                    }
                }
            }
            
            return (count, totalSize, firstAsset)
        }.value
        
        await MainActor.run {
            animateUpdateCategory(id: "live_photos", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "live_photos", asset: asset)
            }
        }
    }
    
    private func scanVideosBackground() async {
        let (count, size, thumbnail) = await Task.detached(priority: .utility) {
            let fetchResult = self.videoService.fetchAllVideos()
            let count = fetchResult.count
            var totalSize: Int64 = 0
            var firstAsset: PHAsset?
            
            fetchResult.enumerateObjects { asset, index, _ in
                if index == 0 { firstAsset = asset }
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first,
                   let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
            
            return (count, totalSize, firstAsset)
        }.value
        
        await MainActor.run {
            animateUpdateCategory(id: "videos", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "videos", asset: asset)
            }
        }
    }
    
    private func scanShortVideosBackground() async {
        let (count, size, thumbnail) = await Task.detached(priority: .utility) {
            let fetchResult = self.videoService.fetchShortVideos()
            let count = fetchResult.count
            var totalSize: Int64 = 0
            var firstAsset: PHAsset?
            
            fetchResult.enumerateObjects { asset, index, _ in
                if index == 0 { firstAsset = asset }
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first,
                   let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
            
            return (count, totalSize, firstAsset)
        }.value
        
        await MainActor.run {
            animateUpdateCategory(id: "short_videos", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "short_videos", asset: asset)
            }
        }
    }
    
    private func scanScreenRecordingsBackground() async {
        let (count, size, thumbnail) = await Task.detached(priority: .utility) {
            let allVideos = self.videoService.fetchScreenRecordings()
            let screenRecordings = self.videoService.filterScreenRecordings(from: allVideos)
            let count = screenRecordings.count
            var totalSize: Int64 = 0
            var firstAsset: PHAsset?
            
            for (index, asset) in screenRecordings.enumerated() {
                if index == 0 { firstAsset = asset }
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += fileSize
                }
            }
            
            return (count, totalSize, firstAsset)
        }.value
        
        await MainActor.run {
            animateUpdateCategory(id: "screen_recordings", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "screen_recordings", asset: asset)
            }
        }
    }
    
    // MARK: - Heavy Categories (Duplicates, Similar, Blurred)
    
    private func scanDuplicatesBackground() async {
        guard !Task.isCancelled else { return }
        await photoService.scanDuplicatesIfNeeded()
    }
    
    private func scanSimilarBackground() async {
        guard !Task.isCancelled else { return }
        await photoService.scanSimilarIfNeeded()
    }
    
    // MARK: - Thumbnails
    
    private func loadThumbnailForDuplicates(groups: [DuplicateGroup]) {
        guard let firstGroup = groups.first,
              let firstAsset = firstGroup.assets.first else { return }
        loadThumbnail(for: "duplicates", asset: firstAsset.asset)
    }
    
    private func loadThumbnailForSimilar(groups: [SimilarGroup]) {
        guard let firstGroup = groups.first,
              let firstAsset = firstGroup.assets.first else { return }
        loadThumbnail(for: "similar", asset: firstAsset.asset)
    }
    
    private func loadThumbnail(for categoryId: String, asset: PHAsset) {
        photoService.loadThumbnail(for: asset, size: CGSize(width: 200, height: 200)) { [weak self] image in
            guard let self = self, let image = image else { return }
            if let index = self.categories.firstIndex(where: { $0.id == categoryId }) {
                self.categories[index].thumbnail = image
            }
        }
    }
    
    // MARK: - Storage Info
    
    private func updateStorageInfo() async {
        await storageService.refreshStorageInfo()
        
        await MainActor.run {
            if let info = storageService.storageInfo {
                withAnimation(.easeInOut(duration: 0.5)) {
                    totalStorage = info.totalSpace
                    totalStorageUsed = info.usedSpace
                }
            }
        }
    }
    
    // MARK: - Animated Updates
    
    private func animateUpdateCategory(id: String, count: Int, size: Int64) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            categories[index].count = count
            categories[index].size = size
            categories[index].isLoading = false
        }
        
        // Пересчитываем totals и сортируем
        calculateTotals()
        sortCategories()
    }
    
    private func calculateTotals() {
        let newClutter = categories.filter { $0.countsTowardsCleanup }.reduce(Int64(0)) { $0 + $1.size }
        let allPhotoVideo = categories.reduce(Int64(0)) { $0 + $1.size }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            clutterSize = newClutter
            spaceToClean = newClutter
            photoVideoSize = allPhotoVideo
        }
    }
    
    private func sortCategories() {
        // Определяем какие категории относятся к фото, а какие к видео
        let photoCategories = Set(["duplicates", "similar", "blurred", "screenshots", "live_photos"])
        let videoCategories = Set(["videos", "short_videos", "screen_recordings"])
        
        withAnimation(.easeInOut(duration: 0.3)) {
            categories.sort { cat1, cat2 in
                let cat1HasContent = cat1.count > 0 || cat1.isLoading
                let cat2HasContent = cat2.count > 0 || cat2.isLoading
                let cat1IsPhoto = photoCategories.contains(cat1.id)
                let cat2IsPhoto = photoCategories.contains(cat2.id)
                let cat1IsVideo = videoCategories.contains(cat1.id)
                let cat2IsVideo = videoCategories.contains(cat2.id)
                
                // 1. Пустые категории в конец
                if cat1HasContent && !cat2HasContent { return true }
                if !cat1HasContent && cat2HasContent { return false }
                
                // 2. Оба пустые - сохраняем порядок: фото, потом видео
                if !cat1HasContent && !cat2HasContent {
                    if cat1IsPhoto && cat2IsVideo { return true }
                    if cat1IsVideo && cat2IsPhoto { return false }
                    return false
                }
                
                // 3. Оба с контентом: фото категории сначала
                if cat1IsPhoto && cat2IsVideo { return true }
                if cat1IsVideo && cat2IsPhoto { return false }
                
                // 4. В рамках одного типа - по размеру (убывание)
                return cat1.size > cat2.size
            }
        }
    }
    
    // MARK: - Photo & Video Size
    
    @Published var photoVideoSize: Int64 = 0
    
    var formattedPhotoVideoSize: String {
        ByteCountFormatter.string(fromByteCount: photoVideoSize, countStyle: .file)
    }
    
    // MARK: - Formatted Values
    
    var formattedSpaceToClean: String {
        ByteCountFormatter.string(fromByteCount: spaceToClean, countStyle: .file)
    }
    
    var formattedClutter: String {
        ByteCountFormatter.string(fromByteCount: clutterSize, countStyle: .file)
    }
    
    var formattedAppsData: String {
        ByteCountFormatter.string(fromByteCount: appsDataSize, countStyle: .file)
    }
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalStorage, countStyle: .file)
    }
    
    var storageUsagePercentage: Double {
        guard totalStorage > 0 else { return 0 }
        return Double(totalStorageUsed) / Double(totalStorage)
    }
    
    var cleanablePercentage: Double {
        guard totalStorage > 0 else { return 0 }
        return min(1.0, Double(spaceToClean) / Double(totalStorage))
    }
    
    var photoVideoPercentage: Double {
        guard totalStorage > 0 else { return 0 }
        return min(1.0, Double(photoVideoSize) / Double(totalStorage))
    }
}

// MARK: - Media Category Model

struct MediaCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    var countsTowardsCleanup: Bool = true
    var count: Int = 0
    var size: Int64 = 0
    var thumbnail: UIImage? = nil
    var isLoading: Bool = true  // Новое поле для индикации загрузки
    
    var formattedSize: String {
        if isLoading && size == 0 {
            return "Scanning..."
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isEmpty: Bool {
        !isLoading && count == 0
    }
}
