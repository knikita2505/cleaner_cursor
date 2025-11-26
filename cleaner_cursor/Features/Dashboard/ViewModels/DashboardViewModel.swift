import SwiftUI
import Photos
import Combine

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = false
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    
    // Storage Stats
    @Published var spaceToClean: Int64 = 0
    @Published var clutterSize: Int64 = 0
    @Published var appsDataSize: Int64 = 0
    @Published var totalStorageUsed: Int64 = 0
    @Published var totalStorage: Int64 = 0
    
    // Categories
    @Published var categories: [MediaCategory] = []
    
    // MARK: - Services
    
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    private let storageService = StorageService.shared
    
    // MARK: - Init
    
    init() {
        setupInitialCategories()
    }
    
    // MARK: - Setup
    
    private func setupInitialCategories() {
        categories = [
            MediaCategory(
                id: "screenshots",
                title: "Screenshots",
                icon: "camera.viewfinder",
                color: AppColors.accentBlue,
                count: 0,
                size: 0,
                thumbnail: nil
            ),
            MediaCategory(
                id: "similar",
                title: "Similar Photos",
                icon: "square.on.square",
                color: AppColors.accentPurple,
                count: 0,
                size: 0,
                thumbnail: nil
            ),
            MediaCategory(
                id: "videos",
                title: "Videos",
                icon: "video.fill",
                color: AppColors.statusWarning,
                count: 0,
                size: 0,
                thumbnail: nil
            ),
            MediaCategory(
                id: "short_videos",
                title: "Short Videos",
                icon: "play.square.stack",
                color: AppColors.statusSuccess,
                count: 0,
                size: 0,
                thumbnail: nil
            ),
            MediaCategory(
                id: "screen_recordings",
                title: "Screen Recordings",
                icon: "record.circle",
                color: AppColors.statusError,
                count: 0,
                size: 0,
                thumbnail: nil
            ),
            MediaCategory(
                id: "live_photos",
                title: "Live Photos",
                icon: "livephoto",
                color: AppColors.accentLilac,
                count: 0,
                size: 0,
                thumbnail: nil
            )
        ]
    }
    
    // MARK: - Scan Media
    
    func scanMedia() async {
        guard photoService.isAuthorized else { return }
        
        isScanning = true
        scanProgress = 0
        
        // Update storage info
        await storageService.refreshStorageInfo()
        if let info = storageService.storageInfo {
            totalStorage = info.totalSpace
            totalStorageUsed = info.usedSpace
        }
        
        // Scan categories sequentially to avoid actor isolation issues
        await scanScreenshots()
        await scanVideos()
        await scanLivePhotos()
        await scanScreenRecordings()
        
        // Calculate totals
        calculateTotals()
        
        isScanning = false
        scanProgress = 1.0
    }
    
    private func scanScreenshots() async {
        let fetchResult = photoService.fetchScreenshots()
        let count = fetchResult.count
        var totalSize: Int64 = 0
        
        fetchResult.enumerateObjects { asset, index, _ in
            // Calculate size
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
            }
            
            // Get first thumbnail
            if index == 0 {
                self.photoService.loadThumbnail(for: asset, size: CGSize(width: 200, height: 200)) { image in
                    Task { @MainActor in
                        self.updateCategoryThumbnail(id: "screenshots", thumbnail: image)
                    }
                }
            }
        }
        
        updateCategory(id: "screenshots", count: count, size: totalSize)
        scanProgress = 0.25
    }
    
    private func scanVideos() async {
        let fetchResult = videoService.fetchAllVideos()
        let count = fetchResult.count
        var totalSize: Int64 = 0
        var shortVideosCount = 0
        var shortVideosSize: Int64 = 0
        
        fetchResult.enumerateObjects { asset, index, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first,
               let size = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += size
                
                // Short videos (< 60 seconds)
                if asset.duration < 60 {
                    shortVideosCount += 1
                    shortVideosSize += size
                }
            }
            
            // Get first thumbnail for videos
            if index == 0 {
                self.videoService.loadThumbnail(for: asset, size: CGSize(width: 200, height: 200)) { image in
                    Task { @MainActor in
                        self.updateCategoryThumbnail(id: "videos", thumbnail: image)
                    }
                }
            }
        }
        
        updateCategory(id: "videos", count: count, size: totalSize)
        updateCategory(id: "short_videos", count: shortVideosCount, size: shortVideosSize)
        scanProgress = 0.5
    }
    
    private func scanLivePhotos() async {
        let fetchResult = photoService.fetchLivePhotos()
        let count = fetchResult.count
        var totalSize: Int64 = 0
        
        fetchResult.enumerateObjects { asset, index, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            for resource in resources {
                if let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
            
            if index == 0 {
                self.photoService.loadThumbnail(for: asset, size: CGSize(width: 200, height: 200)) { image in
                    Task { @MainActor in
                        self.updateCategoryThumbnail(id: "live_photos", thumbnail: image)
                    }
                }
            }
        }
        
        updateCategory(id: "live_photos", count: count, size: totalSize)
        scanProgress = 0.75
    }
    
    private func scanScreenRecordings() async {
        // Screen recordings are videos with specific characteristics
        let fetchResult = videoService.fetchAllVideos()
        var recordingsCount = 0
        var recordingsSize: Int64 = 0
        
        fetchResult.enumerateObjects { asset, _, _ in
            // Screen recordings typically have specific dimensions (device screen size)
            // and no location data
            if asset.pixelWidth == 1170 || asset.pixelWidth == 1284 || asset.pixelWidth == 1179 ||
               asset.pixelWidth == 1080 || asset.pixelWidth == 750 {
                if asset.location == nil {
                    let resources = PHAssetResource.assetResources(for: asset)
                    if let resource = resources.first,
                       let size = resource.value(forKey: "fileSize") as? Int64 {
                        recordingsCount += 1
                        recordingsSize += size
                    }
                }
            }
        }
        
        updateCategory(id: "screen_recordings", count: recordingsCount, size: recordingsSize)
        scanProgress = 1.0
    }
    
    // MARK: - Update Helpers
    
    private func updateCategory(id: String, count: Int, size: Int64) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].count = count
            categories[index].size = size
        }
    }
    
    private func updateCategoryThumbnail(id: String, thumbnail: UIImage?) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].thumbnail = thumbnail
        }
    }
    
    private func calculateTotals() {
        clutterSize = categories.reduce(0) { $0 + $1.size }
        spaceToClean = clutterSize
        
        if let info = storageService.storageInfo {
            appsDataSize = info.usedSpace - clutterSize
            if appsDataSize < 0 { appsDataSize = 0 }
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
        return Double(spaceToClean) / Double(totalStorageUsed)
    }
}

// MARK: - Media Category Model

struct MediaCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    var count: Int
    var size: Int64
    var thumbnail: UIImage?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var isEmpty: Bool {
        count == 0
    }
}
