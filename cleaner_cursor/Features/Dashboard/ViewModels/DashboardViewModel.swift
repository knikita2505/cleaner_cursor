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
        // Порядок согласно requirements/4_dashboard.md
        categories = [
            MediaCategory(id: "duplicates", title: "Duplicate photos", icon: "square.on.square", color: AppColors.statusError, countsTowardsCleanup: true),
            MediaCategory(id: "similar", title: "Similar photos", icon: "square.stack.3d.down.right", color: AppColors.accentPurple, countsTowardsCleanup: true),
            MediaCategory(id: "screenshots", title: "Screenshots", icon: "camera.viewfinder", color: AppColors.accentBlue, countsTowardsCleanup: true),
            MediaCategory(id: "live_photos", title: "Live Photos", icon: "livephoto", color: AppColors.statusWarning, countsTowardsCleanup: true),
            MediaCategory(id: "videos", title: "Videos", icon: "video.fill", color: AppColors.statusSuccess, countsTowardsCleanup: false),
            MediaCategory(id: "short_videos", title: "Short videos", icon: "bolt.fill", color: AppColors.accentBlue.opacity(0.8), countsTowardsCleanup: false),
            MediaCategory(id: "screen_recordings", title: "Screen recordings", icon: "record.circle", color: AppColors.statusError.opacity(0.8), countsTowardsCleanup: false)
        ]
    }
    
    // MARK: - Observe PhotoService Cache
    
    private func observePhotoServiceCache() {
        photoService.$cachedDuplicates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                guard let self = self, !groups.isEmpty else { return }
                let count = groups.reduce(0) { $0 + $1.assets.count - 1 }
                let size = groups.reduce(Int64(0)) { $0 + $1.savingsSize }
                self.animateUpdateCategory(id: "duplicates", count: count, size: size)
                self.loadThumbnailForDuplicates(groups: groups)
            }
            .store(in: &cancellables)
        
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
        
        // 2. Быстрые категории (параллельно, в background)
        await scanFastCategoriesInBackground()
        
        // 3. Тяжёлые категории (дубликаты, похожие)
        if !Task.isCancelled {
            await scanHeavyCategoriesInBackground()
        }
        
        // Завершено
        await MainActor.run {
            self.isScanning = false
            self.scanProgress = ""
            self.hasScannedOnce = true
            self.lastScanTime = Date()
        }
    }
    
    // MARK: - Fast Categories (Screenshots, Live Photos, Videos)
    
    private func scanFastCategoriesInBackground() async {
        await MainActor.run { scanProgress = "Scanning photos..." }
        
        // Запускаем все быстрые категории параллельно
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.scanScreenshotsBackground() }
            group.addTask { await self.scanLivePhotosBackground() }
            group.addTask { await self.scanVideosBackground() }
            group.addTask { await self.scanShortVideosBackground() }
            group.addTask { await self.scanScreenRecordingsBackground() }
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
            let fetchResult = self.videoService.fetchScreenRecordings()
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
            animateUpdateCategory(id: "screen_recordings", count: count, size: size)
            if let asset = thumbnail {
                loadThumbnail(for: "screen_recordings", asset: asset)
            }
        }
    }
    
    // MARK: - Heavy Categories (Duplicates, Similar)
    
    private func scanHeavyCategoriesInBackground() async {
        await MainActor.run { scanProgress = "Finding duplicates..." }
        await photoService.scanDuplicatesIfNeeded()
        
        guard !Task.isCancelled else { return }
        
        await MainActor.run { scanProgress = "Finding similar photos..." }
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
        
        // Пересчитываем totals
        calculateTotals()
    }
    
    private func calculateTotals() {
        let newClutter = categories.filter { $0.countsTowardsCleanup }.reduce(Int64(0)) { $0 + $1.size }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            clutterSize = newClutter
            spaceToClean = newClutter
            
            if let info = storageService.storageInfo {
                appsDataSize = max(0, info.usedSpace - newClutter)
            }
        }
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
        ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }
    
    var storageUsagePercentage: Double {
        guard totalStorage > 0 else { return 0 }
        return Double(totalStorageUsed) / Double(totalStorage)
    }
    
    var cleanablePercentage: Double {
        guard totalStorageUsed > 0 else { return 0 }
        return min(1.0, Double(spaceToClean) / Double(totalStorageUsed))
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
