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
        categories = [
            MediaCategory(id: "screenshots", title: "Screenshots", icon: "camera.viewfinder", color: AppColors.accentBlue, countsTowardsCleanup: true),
            MediaCategory(id: "live_photos", title: "Live Photos", icon: "livephoto", color: AppColors.statusWarning, countsTowardsCleanup: true),
            MediaCategory(id: "duplicates", title: "Duplicates", icon: "square.on.square", color: AppColors.statusError, countsTowardsCleanup: true),
            MediaCategory(id: "similar", title: "Similar Photos", icon: "square.stack.3d.down.right", color: AppColors.accentPurple, countsTowardsCleanup: true),
            MediaCategory(id: "videos", title: "Videos", icon: "video.fill", color: AppColors.statusSuccess, countsTowardsCleanup: false)
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
        // Already scanned?
        if photoService.duplicatesScanned && photoService.similarScanned {
            // Just update quick counts
            updateQuickCounts()
            return
        }
        
        startFullScan()
    }
    
    func forceRefresh() {
        photoService.invalidateCache()
        startFullScan()
    }
    
    private func startFullScan() {
        scanTask?.cancel()
        
        guard photoService.isAuthorized else { return }
        
        isScanning = true
        scanProgress = "Starting scan..."
        
        scanTask = Task {
            await performFullScan()
        }
    }
    
    // MARK: - Full Scan
    
    private func performFullScan() async {
        // 1. Quick counts (instant - just counting)
        updateQuickCounts()
        
        // 2. Storage info
        await updateStorageInfo()
        
        // 3. PRIORITY: Duplicates & Similar - this is the main feature!
        scanProgress = "Finding duplicates..."
        await photoService.scanDuplicatesIfNeeded()
        
        if !Task.isCancelled {
            scanProgress = "Finding similar photos..."
            await photoService.scanSimilarIfNeeded()
        }
        
        // Done
        isScanning = false
        scanProgress = ""
        calculateTotals()
    }
    
    // MARK: - Quick Counts (Instant)
    
    private func updateQuickCounts() {
        // These are instant - just counting from system smart albums
        photoService.updateQuickCounts()
        
        // Update categories with counts (no size for quick scan)
        updateCategory(id: "screenshots", count: photoService.screenshotsCount, size: estimateScreenshotsSize())
        updateCategory(id: "live_photos", count: photoService.livePhotosCount, size: estimateLivePhotosSize())
        updateCategory(id: "videos", count: photoService.videosCount, size: 0)
        
        // Load thumbnails
        loadQuickThumbnails()
    }
    
    // Rough size estimates (average sizes)
    private func estimateScreenshotsSize() -> Int64 {
        // Average screenshot ~500KB
        return Int64(photoService.screenshotsCount) * 500_000
    }
    
    private func estimateLivePhotosSize() -> Int64 {
        // Average Live Photo ~3MB (photo + video)
        return Int64(photoService.livePhotosCount) * 3_000_000
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
