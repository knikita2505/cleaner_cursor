import Foundation
import Photos
import AVFoundation

// MARK: - Video Service
/// Сервис для работы с видео через PhotoKit

@MainActor
final class VideoService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    
    // MARK: - Singleton
    
    static let shared = VideoService()
    
    // MARK: - Private Properties
    
    private let imageManager = PHCachingImageManager()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Fetch Videos
    
    /// Получить все видео
    nonisolated func fetchAllVideos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        return PHAsset.fetchAssets(with: options)
    }
    
    /// Получить большие видео (> 100MB)
    func fetchLargeVideos(minSize: Int64 = 100_000_000) -> [VideoAsset] {
        let fetchResult = fetchAllVideos()
        var largeVideos: [VideoAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            let videoAsset = VideoAsset(asset: asset)
            if videoAsset.fileSize >= minSize {
                largeVideos.append(videoAsset)
            }
        }
        
        return largeVideos.sorted { $0.fileSize > $1.fileSize }
    }
    
    // MARK: - Load Thumbnail
    
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
    
    // MARK: - Video Compression
    
    /// Сжать видео
    func compressVideo(asset: PHAsset, quality: VideoCompressionQuality, completion: @escaping (Result<URL, Error>) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset else {
                completion(.failure(VideoServiceError.assetNotFound))
                return
            }
            
            self.compressAVAsset(avAsset, quality: quality, completion: completion)
        }
    }
    
    private func compressAVAsset(_ asset: AVAsset, quality: VideoCompressionQuality, completion: @escaping (Result<URL, Error>) -> Void) {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: quality.preset) else {
            completion(.failure(VideoServiceError.exportFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed, .cancelled:
                completion(.failure(exportSession.error ?? VideoServiceError.exportFailed))
            default:
                break
            }
        }
    }
    
    // MARK: - Delete Videos
    
    func deleteVideos(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
    
    // MARK: - Statistics
    
    private var isAuthorized: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }
    
    var totalVideosCount: Int {
        guard isAuthorized else { return 0 }
        return fetchAllVideos().count
    }
    
    func calculateTotalVideoSize() -> Int64 {
        guard isAuthorized else { return 0 }
        let fetchResult = fetchAllVideos()
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
}

// MARK: - Video Asset Model

struct VideoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let duration: TimeInterval
    let fileSize: Int64
    var isSelected: Bool = false
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.duration = asset.duration
        
        let resources = PHAssetResource.assetResources(for: asset)
        self.fileSize = resources.first.flatMap { resource in
            (resource.value(forKey: "fileSize") as? Int64)
        } ?? 0
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VideoAsset, rhs: VideoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Video Compression Quality

enum VideoCompressionQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var preset: String {
        switch self {
        case .low: return AVAssetExportPresetLowQuality
        case .medium: return AVAssetExportPresetMediumQuality
        case .high: return AVAssetExportPreset1280x720
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Smallest file size, reduced quality"
        case .medium: return "Balanced size and quality"
        case .high: return "Good quality, moderate compression"
        }
    }
}

// MARK: - Video Service Errors

enum VideoServiceError: LocalizedError {
    case assetNotFound
    case exportFailed
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .assetNotFound: return "Video asset not found"
        case .exportFailed: return "Video export failed"
        case .compressionFailed: return "Video compression failed"
        }
    }
}

import UIKit

