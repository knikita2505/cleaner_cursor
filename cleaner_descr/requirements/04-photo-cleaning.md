# Требования: Очистка фото и видео

## Цель
Реализовать PhotoService и VideoService для сканирования, анализа и удаления медиафайлов через PhotoKit.

---

## Требование 1: PhotoService

### Класс
```swift
@MainActor
class PhotoService: ObservableObject {
    static let shared = PhotoService()
    
    // Публикуемые свойства
    @Published var isScanning = false
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var similarGroups: [SimilarGroup] = []
    @Published var screenshots: [PhotoAsset] = []
    @Published var livePhotos: [LivePhotoAsset] = []
    @Published var burstGroups: [BurstGroup] = []
    @Published var highlights: [PhotoAsset] = []
    
    // Счётчики для быстрого отображения
    @Published var screenshotCount: Int = 0
    @Published var livePhotoCount: Int = 0
    @Published var videoCount: Int = 0
    
    private let cache = ScanResultsCache()
    private let imageManager = PHCachingImageManager()
}
```

### Модели данных

```swift
struct PhotoAsset: Identifiable, Hashable {
    let id: String              // PHAsset.localIdentifier
    let asset: PHAsset
    let creationDate: Date?
    let fileSize: Int64
    let pixelWidth: Int
    let pixelHeight: Int
    var thumbnail: UIImage?
    
    // Hashable по id
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DuplicateGroup: Identifiable {
    let id: UUID
    var assets: [PhotoAsset]
    var bestAsset: PhotoAsset    // Лучшее фото для сохранения
}

struct SimilarGroup: Identifiable {
    let id: UUID
    var assets: [PhotoAsset]
    var bestAsset: PhotoAsset
}

struct BurstGroup: Identifiable {
    let id: UUID
    let burstIdentifier: String
    var assets: [PhotoAsset]
}

struct LivePhotoAsset: Identifiable {
    let id: String
    let asset: PHAsset
    let fileSize: Int64
    var thumbnail: UIImage?
}
```

---

## Требование 2: Поиск дубликатов

### Алгоритм
1. Получить все фото: `PHAsset.fetchAssets(with: .image, options: fetchOptions)`
2. Для каждого фото получить размер файла через `PHAssetResource.assetResources(for:)`
3. Группировать по `fileSize` (одинаковый размер = потенциальный дубликат)
4. Внутри каждой группы проверить дату создания (±1 секунда) для подтверждения
5. Группы с >1 фото = дубликаты
6. Выбрать `bestAsset` = фото с наивысшим разрешением или наиболее раннее

### Оптимизация
- Кэширование результатов в `ScanResultsCache`
- TTL кэша: 1 час (или до изменения библиотеки)
- Сканирование в фоне через `Task { }`
- Обновление UI на главном потоке (`@MainActor`)

### Метод
```swift
func scanDuplicatesIfNeeded() async {
    if cache.isCacheValid(), let cached = cache.getCachedDuplicates() {
        self.duplicateGroups = cached
        return
    }
    
    isScanning = true
    let groups = await findDuplicatesInternal()
    self.duplicateGroups = groups
    cache.saveResults(duplicates: groups, similar: similarGroups)
    isScanning = false
}
```

---

## Требование 3: Поиск похожих фото

### Алгоритм
1. Получить все фото, отсортированные по дате
2. Сравнить соседние фото по времени создания
3. Если разница < 10 секунд → группа похожих (burst-like)
4. Группы с >1 фото = похожие
5. `bestAsset` = фото с наивысшим разрешением

---

## Требование 4: Категории фото

### Скриншоты
```swift
func fetchScreenshots() async -> [PhotoAsset] {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let result = PHAsset.fetchAssets(with: .image, options: options)
    return convertToPhotoAssets(result)
}
```

### Live Photos
```swift
func fetchLivePhotos() async -> [LivePhotoAsset] {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoLive.rawValue)
    // ...
}
```

### Burst Photos
```swift
func fetchBurstPhotos() async -> [BurstGroup] {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "representsBurst == YES")
    // Группировка по burstIdentifier
}
```

### Конвертация Live Photo → Still
```swift
func convertLivePhotoToStill(_ asset: PHAsset) async throws {
    // 1. Запросить полноразмерное изображение
    // 2. Создать новый PHAsset без видео-компонента
    // 3. Удалить оригинальный Live Photo
    // Экономия: ~50% размера (видео-компонент)
}
```

---

## Требование 5: VideoService

### Класс
```swift
@MainActor
class VideoService: ObservableObject {
    static let shared = VideoService()
    
    @Published var allVideos: [VideoAsset] = []
    @Published var largeVideos: [VideoAsset] = []
    @Published var shortVideos: [VideoAsset] = []
}
```

### Модель
```swift
struct VideoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let duration: TimeInterval
    let fileSize: Int64
    var thumbnail: UIImage?
}
```

### Методы
```swift
func fetchAllVideos() async -> [VideoAsset]
func fetchLargeVideos(minSize: Int64 = 100_000_000) async -> [VideoAsset]  // >100MB
func fetchShortVideos(maxDuration: TimeInterval = 10) async -> [VideoAsset] // <10 сек
func compressVideo(asset: PHAsset, quality: VideoCompressionQuality) async throws -> URL
func deleteVideos(_ assets: [PHAsset]) async throws
```

### Сжатие видео
```swift
enum VideoCompressionQuality {
    case low       // AVAssetExportPresetLowQuality
    case medium    // AVAssetExportPresetMediumQuality  
    case high      // AVAssetExportPreset1920x1080
}

func compressVideo(asset: PHAsset, quality: VideoCompressionQuality) async throws -> URL {
    // 1. Получить AVAsset из PHAsset
    // 2. Создать AVAssetExportSession с preset
    // 3. Экспортировать во временный файл
    // 4. Заменить оригинал на сжатый
    // 5. Вернуть URL сжатого файла
}
```

---

## Требование 6: Удаление медиафайлов

### Процесс
```swift
func deletePhotos(_ assets: [PHAsset]) async throws {
    try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.deleteAssets(assets as NSArray)
    }
    // iOS покажет системный диалог подтверждения
    // После подтверждения фото перемещаются в "Recently Deleted"
}
```

### Интеграция с подпиской
```swift
func handleDeletion(assets: [PHAsset]) async throws {
    let permission = SubscriptionManager.shared.canCleanItems(count: assets.count)
    switch permission {
    case .allowed:
        try await deletePhotos(assets)
        SubscriptionManager.shared.recordCleanedItems(count: assets.count)
        CleaningHistoryService.shared.recordCleaning(type: ..., itemsCount: assets.count, bytesFreed: ...)
    case .limitReached(let remaining):
        // Показать paywall или удалить только remaining
        break
    }
}
```

---

## Требование 7: Кэширование результатов сканирования

### ScanResultsCache
```swift
final class ScanResultsCache {
    private let cacheDirectory: URL  // ApplicationSupport/PhotoCache/
    private let cacheFileName = "scan_results.json"
    private let cacheTTL: TimeInterval = 3600  // 1 час
    
    func isCacheValid() -> Bool
    func getCachedDuplicates() -> [DuplicateGroup]?
    func getCachedSimilar() -> [SimilarGroup]?
    func saveResults(duplicates: [DuplicateGroup], similar: [SimilarGroup])
    func clear()
}
```

### Формат кэша
```swift
struct CacheData: Codable {
    let timestamp: Date
    let libraryCount: Int          // количество фото в библиотеке на момент кэширования
    let duplicateGroups: [CachedDuplicateGroup]
    let similarGroups: [CachedSimilarGroup]
}

struct CachedAsset: Codable {
    let localIdentifier: String
    let fileSize: Int64
    let creationDate: Date?
}

struct CachedDuplicateGroup: Codable {
    let id: String
    let assets: [CachedAsset]
    let bestAssetId: String
}
```

Валидация: кэш валиден если `(Date() - timestamp) < cacheTTL` И `libraryCount == currentLibraryCount`

---

## Требование 8: UI экранов фото

### DashboardView
- Карточки категорий с количеством и размером
- Кнопка "Scan" для запуска
- Shimmer при сканировании
- Навигация к деталям по нажатию

### DuplicatesView / SimilarPhotosView
- Список групп с превью
- Чекбоксы для выбора
- "Select All Duplicates" (выбрать все кроме лучшего)
- "Delete Selected" с проверкой лимита
- Сортировка: по размеру, по дате

### ScreenshotsView / LivePhotosView / BurstPhotosView
- Сетка (LazyVGrid, 3 столбца)
- Множественный выбор
- Массовое удаление
- Для Live Photos: кнопка "Convert to Still"

---

## Критерии приёмки

- [ ] PhotoService сканирует все категории
- [ ] Дубликаты находятся корректно (по размеру файла)
- [ ] Кэширование работает (повторное сканирование мгновенно)
- [ ] Удаление вызывает системный диалог iOS
- [ ] Лимит подписки проверяется при удалении
- [ ] Запись в CleaningHistory при каждом удалении
- [ ] Thumbnails кэшируются через PHCachingImageManager
- [ ] UI не зависает при сканировании больших библиотек
