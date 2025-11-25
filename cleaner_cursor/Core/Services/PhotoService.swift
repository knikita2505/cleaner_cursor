import Foundation
import Photos
import UIKit

// MARK: - Photo Service
/// Сервис для работы с фотографиями через PhotoKit

@MainActor
final class PhotoService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    
    // MARK: - Singleton
    
    static let shared = PhotoService()
    
    // MARK: - Private Properties
    
    private let imageManager = PHCachingImageManager()
    
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
        await MainActor.run {
            authorizationStatus = status
        }
        return status == .authorized || status == .limited
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }
    
    // MARK: - Fetch Photos
    
    /// Получить все фото
    func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }
    
    /// Получить скриншоты
    func fetchScreenshots() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType = %d AND (mediaSubtype & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        return PHAsset.fetchAssets(with: options)
    }
    
    /// Получить Live Photos
    func fetchLivePhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType = %d AND (mediaSubtype & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoLive.rawValue
        )
        return PHAsset.fetchAssets(with: options)
    }
    
    /// Получить Burst Photos
    func fetchBurstPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "representsBurst == YES")
        return PHAsset.fetchAssets(with: options)
    }
    
    // MARK: - Load Image
    
    /// Загрузить thumbnail
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
    
    /// Загрузить полное изображение
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
    
    /// Удалить фотографии
    func deletePhotos(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
    
    // MARK: - Statistics
    
    /// Общее количество фото
    var totalPhotosCount: Int {
        guard isAuthorized else { return 0 }
        return fetchAllPhotos().count
    }
    
    /// Количество скриншотов
    var screenshotsCount: Int {
        guard isAuthorized else { return 0 }
        return fetchScreenshots().count
    }
    
    /// Количество Live Photos
    var livePhotosCount: Int {
        guard isAuthorized else { return 0 }
        return fetchLivePhotos().count
    }
    
    /// Количество Burst Photos
    var burstPhotosCount: Int {
        guard isAuthorized else { return 0 }
        return fetchBurstPhotos().count
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
        
        // Get file size
        let resources = PHAssetResource.assetResources(for: asset)
        self.fileSize = resources.first.flatMap { resource in
            (resource.value(forKey: "fileSize") as? Int64)
        } ?? 0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Photo Category

enum PhotoCategory: String, CaseIterable, Identifiable {
    case duplicates = "Duplicates"
    case similar = "Similar"
    case screenshots = "Screenshots"
    case livePhotos = "Live Photos"
    case burst = "Burst"
    case bigFiles = "Big Files"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .duplicates: return "photo.stack"
        case .similar: return "square.on.square"
        case .screenshots: return "camera.viewfinder"
        case .livePhotos: return "livephoto"
        case .burst: return "square.stack.3d.up"
        case .bigFiles: return "doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .duplicates: return AppColors.accentBlue
        case .similar: return AppColors.accentPurple
        case .screenshots: return AppColors.statusSuccess
        case .livePhotos: return AppColors.statusWarning
        case .burst: return AppColors.accentLilac
        case .bigFiles: return AppColors.statusError
        }
    }
}

import SwiftUI

