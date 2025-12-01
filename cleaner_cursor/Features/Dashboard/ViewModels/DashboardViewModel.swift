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
    
    // Storage Stats
    @Published var spaceToClean: Int64 = 0
    @Published var clutterSize: Int64 = 0
    @Published var appsDataSize: Int64 = 0
    @Published var totalStorageUsed: Int64 = 0
    @Published var totalStorage: Int64 = 0
    
    // Categories
    @Published var categories: [MediaCategory] = []
    
    // MARK: - Cache
    
    private var scanTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Services
    
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    
    init() {
        setupCategories()
        observePhotoService()
    }
    
    private func setupCategories() {
        // Порядок согласно requirements/4_dashboard.md:
        // 1. Duplicate photos, 2. Similar photos, 3. Screenshots, 4. Live Photos, 
        // 5. Videos, 6. Short videos, 7. Screen recordings
        categories = [
            MediaCategory(id: "duplicates", title: "Duplicate photos", icon: "square.on.square", color: AppColors.statusError, countsTowardsCleanup: true),
            MediaCategory(id: "similar", title: "Similar photos", icon: "square.stack.3d.down.right", color: AppColors.accentPurple, countsTowardsCleanup: true),
            MediaCategory(id: "screenshots", title: "Screenshots", icon: "camera.viewfinder", color: AppColors.accentBlue, countsTowardsCleanup: true),
            MediaCategory(id: "live_photos", title: "Live Photos", icon: "livephoto", color: AppColors.statusWarning, countsTowardsCleanup: true),
            MediaCategory(id: "videos", title: "Videos", icon: "video.fill", color: AppColors.statusSuccess, countsTowardsCleanup: false),
            MediaCategory(id: "short_videos", title: "Short videos", icon: "bolt.fill", color: AppColors.accentBlue.opacity(0.8), countsTowardsCleanup: false),
            MediaCategory(id: "screen_recordings", title: "Screen recordings", icon: "rectangle.dashed.badge.record", color: AppColors.statusError.opacity(0.8), countsTowardsCleanup: false)
        ]
    }
    
    // MARK: - Observe PhotoService Cache
    
    private func observePhotoService() {
        // Update duplicates count when cache changes
        photoService.$cachedDuplicates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                guard let self = self else { return }
                let count = groups.reduce(0) { $0 + $1.assets.count - 1 }
                let size = groups.reduce(Int64(0)) { $0 + $1.savingsSize }
                self.updateCategory(id: "duplicates", count: count, size: size)
                self.loadThumbnailForCategory(id: "duplicates", groups: groups)
            }
            .store(in: &cancellables)
        
        // Update similar count when cache changes
        photoService.$cachedSimilarPhotos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                guard let self = self else { return }
                let count = groups.reduce(0) { $0 + max(0, $1.assets.count - 1) }
                let size = groups.reduce(Int64(0)) { $0 + $1.savingsSize }
                self.updateCategory(id: "similar", count: count, size: size)
                self.loadThumbnailForSimilar(groups: groups)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Start Scan
    
    func startScanIfNeeded() {
        guard photoService.isAuthorized else { return }
        
        // Always update quick counts first (fast)
        scanProgress = "Loading..."
        isScanning = true
        
        Task {
            // Quick counts for fast categories
            await scanQuickCategories()
            
            // Then scan duplicates and similar if needed
            if !photoService.duplicatesScanned || !photoService.similarScanned {
                await scanHeavyCategories()
            }
            
            isScanning = false
            scanProgress = ""
        }
    }
    
    func forceRefresh() {
        photoService.invalidateCache()
        
        isScanning = true
        scanProgress = "Refreshing..."
        
        Task {
            await scanQuickCategories()
            await scanHeavyCategories()
            
            isScanning = false
            scanProgress = ""
        }
    }
    
    // MARK: - Scan Quick Categories
    
    private func scanQuickCategories() async {
        scanProgress = "Scanning screenshots..."
        
        // Screenshots
        let screenshotsSize = calculateScreenshotsSize()
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCategory(id: "screenshots", count: photoService.screenshotsCount, size: screenshotsSize)
            }
        }
        
        scanProgress = "Scanning Live Photos..."
        
        // Live Photos
        let livePhotosSize = calculateLivePhotosSize()
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCategory(id: "live_photos", count: photoService.livePhotosCount, size: livePhotosSize)
            }
        }
        
        scanProgress = "Scanning videos..."
        
        // Videos (не считаются в cleanup)
        let videosSize = calculateVideosSize()
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCategory(id: "videos", count: videoService.totalVideosCount, size: videosSize)
            }
        }
        
        // Short Videos (не считаются в cleanup)
        let shortVideosSize = calculateShortVideosSize()
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCategory(id: "short_videos", count: videoService.shortVideosCount, size: shortVideosSize)
            }
        }
        
        // Screen Recordings (не считаются в cleanup)
        let screenRecordingsSize = calculateScreenRecordingsSize()
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCategory(id: "screen_recordings", count: videoService.screenRecordingsCount, size: screenRecordingsSize)
            }
        }
        
        // Load thumbnails
        loadQuickThumbnails()
        
        // Update storage info
        await updateStorageInfo()
    }
    
    // MARK: - Scan Heavy Categories (Duplicates & Similar)
    
    private func scanHeavyCategories() async {
        scanProgress = "Finding duplicates..."
        await photoService.scanDuplicatesIfNeeded()
        
        guard !Task.isCancelled else { return }
        
        scanProgress = "Finding similar photos..."
        await photoService.scanSimilarIfNeeded()
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                calculateTotals()
            }
        }
    }
    
    // MARK: - Quick Counts (Instant)
    
    private func updateQuickCounts() {
        // Update counts from photo service cache
        photoService.updateQuickCounts()
    }
    
    // MARK: - Size Calculations
    
    private func calculateScreenshotsSize() -> Int64 {
        let fetchResult = photoService.fetchScreenshots()
        var totalSize: Int64 = 0
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
    
    private func calculateLivePhotosSize() -> Int64 {
        let fetchResult = photoService.fetchLivePhotos()
        var totalSize: Int64 = 0
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            for resource in resources {
                if let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
        }
        return totalSize
    }
    
    private func calculateVideosSize() -> Int64 {
        let fetchResult = videoService.fetchAllVideos()
        var totalSize: Int64 = 0
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
    
    private func calculateShortVideosSize() -> Int64 {
        let fetchResult = videoService.fetchShortVideos()
        var totalSize: Int64 = 0
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
    
    private func calculateScreenRecordingsSize() -> Int64 {
        let fetchResult = videoService.fetchScreenRecordings()
        var totalSize: Int64 = 0
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
    
    // MARK: - Load Thumbnails
    
    private func loadQuickThumbnails() {
        // Screenshots
        let screenshots = photoService.fetchScreenshots()
        if let first = screenshots.firstObject {
            loadThumbnail(for: "screenshots", asset: first)
        }
        
        // Live Photos
        let livePhotos = photoService.fetchLivePhotos()
        if let first = livePhotos.firstObject {
            loadThumbnail(for: "live_photos", asset: first)
        }
        
        // Videos
        let videos = videoService.fetchAllVideos()
        if let first = videos.firstObject {
            loadThumbnail(for: "videos", asset: first)
        }
        
        // Short Videos
        let shortVideos = videoService.fetchShortVideos()
        if let first = shortVideos.firstObject {
            loadThumbnail(for: "short_videos", asset: first)
        }
        
        // Screen Recordings
        let screenRecordings = videoService.fetchScreenRecordings()
        if let first = screenRecordings.firstObject {
            loadThumbnail(for: "screen_recordings", asset: first)
        }
    }
    
    private func loadThumbnailForCategory(id: String, groups: [DuplicateGroup]) {
        guard let firstGroup = groups.first, let firstAsset = firstGroup.assets.first else { return }
        loadThumbnail(for: id, asset: firstAsset.asset)
    }
    
    private func loadThumbnailForSimilar(groups: [SimilarGroup]) {
        guard let firstGroup = groups.first, let firstAsset = firstGroup.assets.first else { return }
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
        
        if let info = storageService.storageInfo {
            totalStorage = info.totalSpace
            totalStorageUsed = info.usedSpace
        }
    }
    
    // MARK: - Helpers
    
    private func updateCategory(id: String, count: Int, size: Int64) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].count = count
            categories[index].size = size
        }
        calculateTotals()
    }
    
    private func calculateTotals() {
        clutterSize = categories.filter { $0.countsTowardsCleanup }.reduce(0) { $0 + $1.size }
        spaceToClean = clutterSize
        
        if let info = storageService.storageInfo {
            appsDataSize = max(0, info.usedSpace - clutterSize)
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
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isEmpty: Bool {
        count == 0
    }
}
