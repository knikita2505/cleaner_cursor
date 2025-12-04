import Foundation
import Photos
import UIKit
import CoreImage

// MARK: - Photo Service
/// Сервис для работы с фотографиями через PhotoKit

@MainActor
final class PhotoService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    
    // MARK: - Cached Results
    
    @Published var cachedDuplicates: [DuplicateGroup] = []
    @Published var cachedSimilarPhotos: [SimilarGroup] = []
    @Published var duplicatesScanned: Bool = false
    @Published var similarScanned: Bool = false
    
    // Quick counts (no size calculation)
    @Published var screenshotsCount: Int = 0
    @Published var livePhotosCount: Int = 0
    @Published var videosCount: Int = 0
    
    // MARK: - Singleton
    
    static let shared = PhotoService()
    
    // MARK: - Private Properties
    
    private let imageManager = PHCachingImageManager()
    private var lastScanTime: Date?
    private let cacheValidityMinutes: Double = 10
    
    // MARK: - Init
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status == .authorized || status == .limited
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }
    
    // MARK: - Quick Counts (System folders - instant)
    
    func updateQuickCounts() {
        guard isAuthorized else { return }
        
        // These are instant - just counting from system folders
        let screenshotsFetch = fetchScreenshots()
        screenshotsCount = screenshotsFetch.count
        
        let livePhotosFetch = fetchLivePhotos()
        livePhotosCount = livePhotosFetch.count
        
        let videosFetch = VideoService.shared.fetchAllVideos()
        videosCount = videosFetch.count
    }
    
    // MARK: - Scan Duplicates & Similar (with persistent caching)
    
    private let resultsCache = ScanResultsCache.shared
    
    func scanDuplicatesIfNeeded() async {
        guard !duplicatesScanned else { return }
        
        isScanning = true
        
        // Всё выполняем в background чтобы не блокировать UI
        let groups = await Task.detached(priority: .userInitiated) { [resultsCache] in
            // Проверяем persistent кэш (в background!)
            if resultsCache.isCacheValid(), let cached = resultsCache.getCachedDuplicates() {
                return cached
            }
            // Кэш невалиден - сканируем
            return self.findDuplicatesInternal()
        }.value
        
        cachedDuplicates = groups
        duplicatesScanned = true
        isScanning = false
    }
    
    func scanSimilarIfNeeded() async {
        guard !similarScanned else { return }
        
        isScanning = true
        
        // Всё выполняем в background чтобы не блокировать UI
        let (groups, shouldSaveCache) = await Task.detached(priority: .userInitiated) { [resultsCache] in
            // Проверяем persistent кэш (в background!)
            if resultsCache.isCacheValid(), let cached = resultsCache.getCachedSimilar() {
                return (cached, false)
            }
            // Кэш невалиден - сканируем
            return (self.findSimilarPhotosInternal(), true)
        }.value
        
        cachedSimilarPhotos = groups
        similarScanned = true
        isScanning = false
        
        // Сохраняем оба результата в persistent кэш (если сканировали)
        if shouldSaveCache {
            resultsCache.saveResults(duplicates: cachedDuplicates, similar: cachedSimilarPhotos)
        }
    }
    
    func invalidateCache() {
        duplicatesScanned = false
        similarScanned = false
        cachedDuplicates = []
        cachedSimilarPhotos = []
        resultsCache.clear()
    }
    
    // MARK: - Duplicates Stats (from cache)
    
    var duplicatesCount: Int {
        cachedDuplicates.reduce(0) { $0 + $1.assets.count - 1 }
    }
    
    var duplicatesSavingsSize: Int64 {
        cachedDuplicates.reduce(Int64(0)) { $0 + $1.savingsSize }
    }
    
    // MARK: - Similar Stats (from cache)
    
    var similarCount: Int {
        cachedSimilarPhotos.reduce(0) { $0 + max(0, $1.assets.count - 1) }
    }
    
    var similarSavingsSize: Int64 {
        cachedSimilarPhotos.reduce(Int64(0)) { $0 + $1.savingsSize }
    }
    
    // MARK: - Fetch All Photos
    
    nonisolated func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }
    
    // MARK: - Fetch Screenshots
    
    nonisolated func fetchScreenshots() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType = %d AND (mediaSubtype & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        return PHAsset.fetchAssets(with: options)
    }
    
    /// Получить скриншоты как PhotoAsset массив
    func fetchScreenshotsAsAssets() -> [PhotoAsset] {
        guard isAuthorized else { return [] }
        let fetchResult = fetchScreenshots()
        var assets: [PhotoAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(PhotoAsset(asset: asset))
        }
        
        return assets
    }
    
    // MARK: - Fetch Live Photos
    
    nonisolated func fetchLivePhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType = %d AND (mediaSubtype & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoLive.rawValue
        )
        return PHAsset.fetchAssets(with: options)
    }
    
    func fetchLivePhotosAsAssets() -> [PhotoAsset] {
        guard isAuthorized else { return [] }
        let fetchResult = fetchLivePhotos()
        var assets: [PhotoAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(PhotoAsset(asset: asset))
        }
        
        return assets
    }
    
    // MARK: - Fetch Screen Recordings
    
    nonisolated func fetchScreenRecordings() -> [PHAsset] {
        // Получаем все видео и фильтруем по subtype
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let allVideos = PHAsset.fetchAssets(with: options)
        
        var screenRecordings: [PHAsset] = []
        allVideos.enumerateObjects { asset, _, _ in
            // PHAssetMediaSubtype.videoScreenRecording = 8192 (1 << 13)
            if asset.mediaSubtypes.rawValue & 8192 != 0 {
                screenRecordings.append(asset)
            }
        }
        return screenRecordings
    }
    
    // MARK: - Fetch Blurred Photos
    
    nonisolated func findBlurredPhotos(limit: Int = 500) -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        options.fetchLimit = limit
        
        let fetchResult = PHAsset.fetchAssets(with: options)
        var blurredPhotos: [PhotoAsset] = []
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast
        
        fetchResult.enumerateObjects { asset, _, stop in
            // Request small image for blur detection
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                guard let image = image,
                      let ciImage = CIImage(image: image) else { return }
                
                if self.isBlurred(ciImage) {
                    blurredPhotos.append(PhotoAsset(asset: asset))
                }
            }
            
            // Stop if we found enough
            if blurredPhotos.count >= 100 {
                stop.pointee = true
            }
        }
        
        return blurredPhotos
    }
    
    private nonisolated func isBlurred(_ image: CIImage) -> Bool {
        // Use Laplacian variance to detect blur
        // Lower variance = more blurred
        let context = CIContext()
        
        // Apply edge detection filter
        guard let filter = CIFilter(name: "CILaplacian") else { return false }
        filter.setValue(image, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return false }
        
        // Calculate variance of the Laplacian
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let colorSpace = cgImage.colorSpace,
              let contextRef = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return false }
        
        contextRef.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = contextRef.data else { return false }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var sum: Double = 0
        var sumSq: Double = 0
        let pixelCount = Double(width * height)
        
        for i in stride(from: 0, to: width * height * bytesPerPixel, by: bytesPerPixel) {
            let gray = Double(buffer[i]) // Red channel as grayscale approximation
            sum += gray
            sumSq += gray * gray
        }
        
        let mean = sum / pixelCount
        let variance = (sumSq / pixelCount) - (mean * mean)
        
        // Threshold: lower variance indicates blur
        // Typical threshold is around 100-500 depending on image
        return variance < 100
    }
    
    // MARK: - Fetch Burst Photos
    
    func fetchBurstPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "representsBurst == YES")
        return PHAsset.fetchAssets(with: options)
    }
    
    func fetchBurstGroups() -> [BurstGroup] {
        guard isAuthorized else { return [] }
        
        var burstGroups: [String: BurstGroup] = [:]
        let fetchResult = fetchBurstPhotos()
        
        fetchResult.enumerateObjects { asset, _, _ in
            guard let burstIdentifier = asset.burstIdentifier else { return }
            
            if var group = burstGroups[burstIdentifier] {
                group.assets.append(PhotoAsset(asset: asset))
                burstGroups[burstIdentifier] = group
            } else {
                burstGroups[burstIdentifier] = BurstGroup(
                    id: burstIdentifier,
                    assets: [PhotoAsset(asset: asset)],
                    date: asset.creationDate
                )
            }
        }
        
        return Array(burstGroups.values).sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
    
    // MARK: - Fetch Big Files
    
    func fetchBigPhotos(minSize: Int64 = 20_000_000) -> [PhotoAsset] {
        guard isAuthorized else { return [] }
        
        let fetchResult = fetchAllPhotos()
        var bigPhotos: [PhotoAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            let photoAsset = PhotoAsset(asset: asset)
            if photoAsset.fileSize >= minSize {
                bigPhotos.append(photoAsset)
            }
        }
        
        return bigPhotos.sorted { $0.fileSize > $1.fileSize }
    }
    
    // MARK: - Find Duplicates (Internal - for caching)
    
    /// Поиск точных дубликатов
    /// Дубликат = фото с ТОЧНО одинаковым размером файла + разрешением + близкой датой создания
    private nonisolated func findDuplicatesInternal() -> [DuplicateGroup] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        // Группируем по: размер файла (в байтах) + разрешение
        var compositeGroups: [String: [PhotoAsset]] = [:]
        
        fetchResult.enumerateObjects { asset, _, _ in
            // Пропускаем скриншоты
            if asset.mediaSubtypes.contains(.photoScreenshot) { return }
            
            let photoAsset = PhotoAsset(asset: asset)
            
            // Используем только файлы с ненулевым размером
            guard photoAsset.fileSize > 0 else { return }
            
            // Ключ: точный размер файла + разрешение
            let sizeKey = "\(photoAsset.fileSize)_\(asset.pixelWidth)x\(asset.pixelHeight)"
            
            if compositeGroups[sizeKey] != nil {
                compositeGroups[sizeKey]?.append(photoAsset)
            } else {
                compositeGroups[sizeKey] = [photoAsset]
            }
        }
        
        var duplicateGroups: [DuplicateGroup] = []
        
        // Для каждой группы с одинаковым размером и разрешением
        // дополнительно проверяем близость по времени создания
        for (_, assets) in compositeGroups where assets.count > 1 {
            // Сортируем по дате создания
            let sortedByDate = assets.sorted { 
                ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) 
            }
            
            var currentGroup: [PhotoAsset] = []
            
            for asset in sortedByDate {
                if currentGroup.isEmpty {
                    currentGroup.append(asset)
                } else if let lastDate = currentGroup.last?.creationDate,
                          let currentDate = asset.creationDate,
                          abs(currentDate.timeIntervalSince(lastDate)) <= 60 {
                    // В пределах 60 секунд - это дубликат
                    currentGroup.append(asset)
                } else {
                    // Время разное - сохраняем текущую группу если >= 2 фото
                    if currentGroup.count > 1 {
                        duplicateGroups.append(createDuplicateGroup(from: currentGroup))
                    }
                    currentGroup = [asset]
                }
            }
            
            // Последняя группа
            if currentGroup.count > 1 {
                duplicateGroups.append(createDuplicateGroup(from: currentGroup))
            }
        }
        
        return duplicateGroups.sorted { $0.savingsSize > $1.savingsSize }
    }
    
    private nonisolated func createDuplicateGroup(from assets: [PhotoAsset]) -> DuplicateGroup {
        let sortedByQuality = assets.sorted { $0.fileSize > $1.fileSize }
        let totalSize = assets.reduce(Int64(0)) { $0 + $1.fileSize }
        let bestAsset = sortedByQuality.first
        let savingsSize = totalSize - (bestAsset?.fileSize ?? 0)
        
        return DuplicateGroup(
            id: UUID().uuidString,
            assets: sortedByQuality,
            totalSize: totalSize,
            savingsSize: savingsSize,
            bestAssetIndex: 0
        )
    }
    
    // MARK: - Find Similar Photos (Internal - for caching)
    
    /// Поиск похожих фото:
    /// 1. Burst-серии (фото с одинаковым burstIdentifier)
    /// 2. Фото, сделанные в течение 5 секунд друг от друга
    private nonisolated func findSimilarPhotosInternal() -> [SimilarGroup] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        // Сканируем ВСЕ фото без лимита
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var burstGroups: [String: [PhotoAsset]] = [:]
        var processedIds: Set<String> = []
        
        // 1. Находим burst-серии (они точно похожи)
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaSubtypes.contains(.photoScreenshot) { return }
            
            if let burstId = asset.burstIdentifier {
                let photoAsset = PhotoAsset(asset: asset)
                if burstGroups[burstId] != nil {
                    burstGroups[burstId]?.append(photoAsset)
                } else {
                    burstGroups[burstId] = [photoAsset]
                }
                processedIds.insert(asset.localIdentifier)
            }
        }
        
        // 2. Группируем остальные по времени (5 секунд между фото)
        var remainingPhotos: [PhotoAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaSubtypes.contains(.photoScreenshot) { return }
            if processedIds.contains(asset.localIdentifier) { return }
            
            remainingPhotos.append(PhotoAsset(asset: asset))
        }
        
        // Уже отсортированы по дате (ascending)
        var timeGroups: [[PhotoAsset]] = []
        var currentTimeGroup: [PhotoAsset] = []
        
        for photo in remainingPhotos {
            if currentTimeGroup.isEmpty {
                currentTimeGroup.append(photo)
            } else if let lastDate = currentTimeGroup.last?.creationDate,
                      let currentDate = photo.creationDate,
                      abs(currentDate.timeIntervalSince(lastDate)) <= 5 {
                currentTimeGroup.append(photo)
            } else {
                if currentTimeGroup.count >= 2 {
                    timeGroups.append(currentTimeGroup)
                }
                currentTimeGroup = [photo]
            }
        }
        if currentTimeGroup.count >= 2 {
            timeGroups.append(currentTimeGroup)
        }
        
        var similarGroups: [SimilarGroup] = []
        
        // Добавляем burst-группы
        for (_, assets) in burstGroups where assets.count >= 2 {
            similarGroups.append(createSimilarGroup(from: assets, isBurst: true))
        }
        
        // Добавляем группы по времени
        for assets in timeGroups {
            similarGroups.append(createSimilarGroup(from: assets, isBurst: false))
        }
        
        return similarGroups.sorted { $0.savingsSize > $1.savingsSize }
    }
    
    private nonisolated func createSimilarGroup(from assets: [PhotoAsset], isBurst: Bool) -> SimilarGroup {
        let sortedByQuality = assets.sorted { $0.fileSize > $1.fileSize }
        
        let totalSize = assets.reduce(Int64(0)) { $0 + $1.fileSize }
        let bestAsset = sortedByQuality.first
        let savingsSize = totalSize - (bestAsset?.fileSize ?? 0)
        
        return SimilarGroup(
            id: UUID().uuidString,
            assets: sortedByQuality,
            totalSize: totalSize,
            savingsSize: savingsSize,
            recommendedKeepCount: 1,
            bestAssetIndex: 0,
            isBurstGroup: isBurst
        )
    }
    
    // MARK: - Public API (use cache)
    
    nonisolated func findDuplicates() -> [DuplicateGroup] {
        // This is called from background - returns fresh scan
        return findDuplicatesInternal()
    }
    
    nonisolated func findSimilarPhotos() -> [SimilarGroup] {
        // This is called from background - returns fresh scan
        return findSimilarPhotosInternal()
    }
    
    // MARK: - Highlights (AI-lite)
    
    func findHighlights(limit: Int = 50) -> [PhotoAsset] {
        guard isAuthorized else { return [] }
        
        let fetchResult = fetchAllPhotos()
        var candidates: [(asset: PhotoAsset, score: Double)] = []
        
        fetchResult.enumerateObjects { asset, index, stop in
            if index >= 500 { stop.pointee = true; return }
            
            var score: Double = 0
            let photoAsset = PhotoAsset(asset: asset)
            
            if !asset.mediaSubtypes.contains(.photoScreenshot) {
                score += 1.0
            }
            
            if !asset.mediaSubtypes.contains(.photoLive) {
                score += 0.5
            }
            
            let megapixels = Double(asset.pixelWidth * asset.pixelHeight) / 1_000_000
            if megapixels > 8 {
                score += 1.0
            }
            
            if asset.location != nil {
                score += 0.5
            }
            
            if asset.isFavorite {
                score += 2.0
            }
            
            if photoAsset.fileSize > 2_000_000 {
                score += 0.5
            }
            
            candidates.append((photoAsset, score))
        }
        
        return candidates
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.asset }
    }
    
    // MARK: - Load Image
    
    func loadThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    func loadFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    // MARK: - Delete Photos
    
    func deletePhotos(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
        // Invalidate cache after deletion
        invalidateCache()
    }
    
    func deletePhotoAssets(_ assets: [PhotoAsset]) async throws {
        let phAssets = assets.map { $0.asset }
        try await deletePhotos(phAssets)
    }
    
    // MARK: - Convert Live Photo to Still
    
    func convertLivePhotoToStill(_ asset: PHAsset) async throws {
        guard asset.mediaSubtypes.contains(.photoLive) else { return }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
        var stillImage: UIImage?
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            stillImage = image
        }
        
        guard let image = stillImage, let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw PhotoServiceError.conversionFailed
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: nil)
            request.creationDate = asset.creationDate
            request.location = asset.location
        }
        
        try await deletePhotos([asset])
    }
    
    // MARK: - Fetch Live Photos as Models
    
    func fetchLivePhotosAsModels() -> [LivePhotoAsset] {
        guard isAuthorized else { return [] }
        
        let fetchResult = fetchLivePhotos()
        var result: [LivePhotoAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            
            var photoSize: Int64 = 0
            var videoSize: Int64 = 0
            
            for resource in resources {
                let size = (resource.value(forKey: "fileSize") as? Int64) ?? 0
                
                switch resource.type {
                case .photo, .fullSizePhoto:
                    photoSize += size
                case .pairedVideo, .fullSizePairedVideo:
                    videoSize += size
                default:
                    break
                }
            }
            
            result.append(LivePhotoAsset(
                asset: asset,
                photoSize: photoSize,
                videoSize: videoSize
            ))
        }
        
        return result
    }
    
    // MARK: - Create Album
    
    func createAlbum(name: String, with assets: [PHAsset]) async throws {
        guard isAuthorized else {
            throw PhotoServiceError.notAuthorized
        }
        
        var albumPlaceholder: PHObjectPlaceholder?
        
        try await PHPhotoLibrary.shared().performChanges {
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }
        
        guard let placeholder = albumPlaceholder else {
            throw PhotoServiceError.albumCreationFailed
        }
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [placeholder.localIdentifier],
            options: nil
        )
        
        guard let album = fetchResult.firstObject else {
            throw PhotoServiceError.albumCreationFailed
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album) else { return }
            addAssetRequest.addAssets(assets as NSFastEnumeration)
        }
    }
    
    // MARK: - Add to Existing Album
    
    func addToAlbum(_ albumName: String, assets: [PHAsset]) async throws {
        guard isAuthorized else {
            throw PhotoServiceError.notAuthorized
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = albums.firstObject {
            try await PHPhotoLibrary.shared().performChanges {
                guard let request = PHAssetCollectionChangeRequest(for: existingAlbum) else { return }
                request.addAssets(assets as NSFastEnumeration)
            }
        } else {
            try await createAlbum(name: albumName, with: assets)
        }
    }
}

// MARK: - Photo Asset Model

struct PhotoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let fileSize: Int64
    var isSelected: Bool = false
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        
        let resources = PHAssetResource.assetResources(for: asset)
        self.fileSize = resources.first.flatMap { resource in
            (resource.value(forKey: "fileSize") as? Int64)
        } ?? 0
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        guard let date = creationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var isScreenshot: Bool {
        asset.mediaSubtypes.contains(.photoScreenshot)
    }
    
    var isLivePhoto: Bool {
        asset.mediaSubtypes.contains(.photoLive)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Duplicate Group Model

struct DuplicateGroup: Identifiable {
    let id: String
    var assets: [PhotoAsset]
    let totalSize: Int64
    let savingsSize: Int64
    var bestAssetIndex: Int = 0
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var count: Int {
        assets.count
    }
    
    var deleteIndices: Set<Int> {
        Set(assets.indices.filter { $0 != bestAssetIndex })
    }
    
    var deleteCount: Int {
        assets.count - 1
    }
}

// MARK: - Similar Group Model

struct SimilarGroup: Identifiable {
    let id: String
    var assets: [PhotoAsset]
    let totalSize: Int64
    let savingsSize: Int64
    let recommendedKeepCount: Int
    var bestAssetIndex: Int = 0
    let isBurstGroup: Bool
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var count: Int {
        assets.count
    }
}

// MARK: - Burst Group Model

struct BurstGroup: Identifiable {
    let id: String
    var assets: [PhotoAsset]
    let date: Date?
    
    var count: Int {
        assets.count
    }
    
    var formattedDate: String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Live Photo Asset Model

struct LivePhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset
    let photoSize: Int64
    let videoSize: Int64
    var action: LivePhotoAction = .keepLive
    
    init(asset: PHAsset, photoSize: Int64, videoSize: Int64) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.photoSize = photoSize
        self.videoSize = videoSize
    }
    
    var totalSize: Int64 {
        photoSize + videoSize
    }
    
    var formattedVideoSize: String {
        ByteCountFormatter.string(fromByteCount: videoSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSavings: String {
        // Savings = video size (what we remove when converting)
        ByteCountFormatter.string(fromByteCount: videoSize, countStyle: .file)
    }
    
    var creationDate: Date? {
        asset.creationDate
    }
    
    var formattedDate: String {
        guard let date = creationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Action Enum
    
    enum LivePhotoAction: String, CaseIterable {
        case keepLive = "Keep"
        case convert = "Convert"
        case delete = "Delete"
    }
}

// MARK: - Errors

enum PhotoServiceError: Error, LocalizedError {
    case notAuthorized
    case fetchFailed
    case deleteFailed
    case conversionFailed
    case albumCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Photo library access not authorized"
        case .fetchFailed:
            return "Failed to fetch photos"
        case .deleteFailed:
            return "Failed to delete photos"
        case .conversionFailed:
            return "Failed to convert Live Photo"
        case .albumCreationFailed:
            return "Failed to create album"
        }
    }
}
