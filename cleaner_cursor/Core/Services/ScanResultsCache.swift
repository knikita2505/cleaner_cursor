import Foundation
import Photos

// MARK: - Scan Results Cache
/// Кэш результатов сканирования дубликатов и похожих фото
/// Сохраняет группы в JSON для быстрой загрузки при повторных запусках

final class ScanResultsCache {
    
    static let shared = ScanResultsCache()
    
    // MARK: - Cache Models
    
    private struct CachedDuplicateGroup: Codable {
        let id: String
        let assetIds: [String]
        let totalSize: Int64
        let savingsSize: Int64
        let bestAssetIndex: Int
    }
    
    private struct CachedSimilarGroup: Codable {
        let id: String
        let assetIds: [String]
        let totalSize: Int64
        let savingsSize: Int64
        let recommendedKeepCount: Int
        let bestAssetIndex: Int
        let isBurstGroup: Bool
    }
    
    private struct CacheData: Codable {
        let photoCount: Int
        let lastScanDate: Date
        let assetIdentifiers: Set<String>
        let duplicateGroups: [CachedDuplicateGroup]
        let similarGroups: [CachedSimilarGroup]
    }
    
    // MARK: - Properties
    
    private var cachedData: CacheData?
    private let cacheURL: URL?
    
    // MARK: - Init
    
    private init() {
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let cacheDir = appSupport.appendingPathComponent("PhotoCache", isDirectory: true)
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            cacheURL = cacheDir.appendingPathComponent("scan_results.json")
        } else {
            cacheURL = nil
        }
        loadCache()
    }
    
    // MARK: - Load / Save
    
    private func loadCache() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            cachedData = try JSONDecoder().decode(CacheData.self, from: data)
        } catch {
            print("ScanResultsCache: Failed to load cache - \(error)")
            cachedData = nil
        }
    }
    
    private func saveCache() {
        guard let url = cacheURL, let data = cachedData else { return }
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let jsonData = try JSONEncoder().encode(data)
                try jsonData.write(to: url, options: .atomic)
            } catch {
                print("ScanResultsCache: Failed to save cache - \(error)")
            }
        }
    }
    
    // MARK: - Check Cache Validity
    
    /// Проверяет актуальность кэша
    /// Возвращает true если кэш валиден и можно использовать
    func isCacheValid() -> Bool {
        guard let cached = cachedData else { return false }
        
        // Быстрая проверка - только количество
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)
        
        // Если количество отличается - кэш невалиден
        if result.count != cached.photoCount {
            return false
        }
        
        // Количество совпало - доверяем кэшу
        // (полная проверка идентификаторов слишком медленная)
        return true
    }
    
    // MARK: - Get Cached Results
    
    /// Получить кэшированные группы дубликатов
    func getCachedDuplicates() -> [DuplicateGroup]? {
        guard let cached = cachedData, !cached.duplicateGroups.isEmpty else { return nil }
        
        var groups: [DuplicateGroup] = []
        
        for cachedGroup in cached.duplicateGroups {
            // Загружаем assets по идентификаторам
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: cachedGroup.assetIds, options: nil)
            var assets: [PhotoAsset] = []
            
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(PhotoAsset(asset: asset))
            }
            
            // Пропускаем группу если не все фото найдены
            guard assets.count == cachedGroup.assetIds.count, assets.count > 1 else { continue }
            
            // Восстанавливаем порядок
            let orderedAssets = cachedGroup.assetIds.compactMap { id in
                assets.first { $0.id == id }
            }
            
            guard orderedAssets.count == assets.count else { continue }
            
            groups.append(DuplicateGroup(
                id: cachedGroup.id,
                assets: orderedAssets,
                totalSize: cachedGroup.totalSize,
                savingsSize: cachedGroup.savingsSize,
                bestAssetIndex: cachedGroup.bestAssetIndex
            ))
        }
        
        return groups.isEmpty ? nil : groups
    }
    
    /// Получить кэшированные группы похожих фото
    func getCachedSimilar() -> [SimilarGroup]? {
        guard let cached = cachedData, !cached.similarGroups.isEmpty else { return nil }
        
        var groups: [SimilarGroup] = []
        
        for cachedGroup in cached.similarGroups {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: cachedGroup.assetIds, options: nil)
            var assets: [PhotoAsset] = []
            
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(PhotoAsset(asset: asset))
            }
            
            guard assets.count == cachedGroup.assetIds.count, assets.count > 1 else { continue }
            
            let orderedAssets = cachedGroup.assetIds.compactMap { id in
                assets.first { $0.id == id }
            }
            
            guard orderedAssets.count == assets.count else { continue }
            
            groups.append(SimilarGroup(
                id: cachedGroup.id,
                assets: orderedAssets,
                totalSize: cachedGroup.totalSize,
                savingsSize: cachedGroup.savingsSize,
                recommendedKeepCount: cachedGroup.recommendedKeepCount,
                bestAssetIndex: cachedGroup.bestAssetIndex,
                isBurstGroup: cachedGroup.isBurstGroup
            ))
        }
        
        return groups.isEmpty ? nil : groups
    }
    
    // MARK: - Save Results
    
    /// Сохранить результаты сканирования в кэш
    func saveResults(duplicates: [DuplicateGroup], similar: [SimilarGroup]) {
        // Получаем текущее состояние библиотеки
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)
        
        var assetIds = Set<String>()
        result.enumerateObjects { asset, _, _ in
            assetIds.insert(asset.localIdentifier)
        }
        
        // Конвертируем группы для сохранения
        let cachedDuplicates = duplicates.map { group in
            CachedDuplicateGroup(
                id: group.id,
                assetIds: group.assets.map { $0.id },
                totalSize: group.totalSize,
                savingsSize: group.savingsSize,
                bestAssetIndex: group.bestAssetIndex
            )
        }
        
        let cachedSimilar = similar.map { group in
            CachedSimilarGroup(
                id: group.id,
                assetIds: group.assets.map { $0.id },
                totalSize: group.totalSize,
                savingsSize: group.savingsSize,
                recommendedKeepCount: group.recommendedKeepCount,
                bestAssetIndex: group.bestAssetIndex,
                isBurstGroup: group.isBurstGroup
            )
        }
        
        cachedData = CacheData(
            photoCount: result.count,
            lastScanDate: Date(),
            assetIdentifiers: assetIds,
            duplicateGroups: cachedDuplicates,
            similarGroups: cachedSimilar
        )
        
        saveCache()
    }
    
    // MARK: - Clear
    
    func clear() {
        cachedData = nil
        if let url = cacheURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Info
    
    var hasCachedData: Bool {
        cachedData != nil
    }
    
    var lastScanDate: Date? {
        cachedData?.lastScanDate
    }
}

