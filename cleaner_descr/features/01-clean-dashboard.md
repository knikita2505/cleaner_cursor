# Функция: Clean (Dashboard) — Главный экран очистки

## Общее описание

Dashboard — центральный экран приложения (вкладка Clean). Отображает текущее состояние хранилища устройства, результаты сканирования медиафайлов и предоставляет быстрый доступ ко всем категориям очистки.

**Файлы реализации:**
- `Features/Dashboard/Views/DashboardView.swift` — UI экрана
- `Features/Dashboard/ViewModels/DashboardViewModel.swift` — бизнес-логика (432 строки)
- `Core/Services/PhotoService.swift` — сервис работы с фото (935 строк)
- `Core/Services/VideoService.swift` — сервис работы с видео
- `Core/Services/StorageService.swift` — информация о хранилище

---

## Блоки функции

### Блок 1: Индикатор хранилища

**Что отображает:**
- Круговой прогресс-бар использованного хранилища (процент)
- Числовые значения: использовано / всего (например, "48.2 GB / 64 GB")
- Цветовая индикация: градиент от оранжевого (#FF8D4D) к жёлтому (#FFD36B)

**Техническая реализация:**
- `StorageService.shared.refreshStorageInfo()` — получение данных через `FileManager.default.attributesOfFileSystem`
- `StorageInfo` struct: `totalSpace`, `usedSpace`, `freeSpace` (в байтах)
- `formatBytes(_:)` — форматирование размера в человекочитаемый вид (KB, MB, GB)
- `CircularProgress` UI-компонент с анимацией заполнения

### Блок 2: Статус сканирования

**Что отображает:**
- Состояние сканирования: "Scanning...", "Found X items", результаты
- Анимация shimmer во время сканирования
- Общее количество найденных элементов для очистки

**Техническая реализация:**
- `DashboardViewModel.isScanning` — флаг состояния сканирования
- `startScan()` — запуск сканирования всех категорий
- Фоновое сканирование через `Task { }` с `@MainActor` для обновления UI
- Shimmer-эффект через `ShimmerModifier` (View extension)

### Блок 3: Категории медиафайлов

Каждая категория представлена карточкой `ListCard` с иконкой, названием, количеством найденных элементов и размером.

#### 3.1. Duplicate Photos (Дубликаты фото)
- **Алгоритм поиска:** Сравнение по размеру файла и дате создания. Фото с одинаковым размером в байтах группируются, затем проверяются по дате (±1 секунда)
- **Кэширование:** Результаты сохраняются в `ScanResultsCache` (JSON в ApplicationSupport/PhotoCache/)
- **Сервис:** `PhotoService.scanDuplicatesIfNeeded()` → `findDuplicatesInternal()`
- **Модель:** `DuplicateGroup` — группа дубликатов с массивом `PhotoAsset`
- **Экран деталей:** `DuplicatesView.swift`

#### 3.2. Similar Photos (Похожие фото)
- **Алгоритм поиска:** Группировка фото, снятых в пределах короткого временного интервала (burst-like). Сравнение по дате создания с порогом в несколько секунд
- **Кэширование:** Результаты в `ScanResultsCache` совместно с дубликатами
- **Сервис:** `PhotoService.scanSimilarIfNeeded()` → `findSimilarPhotosInternal()`
- **Модель:** `SimilarGroup` — группа похожих фото
- **Экран деталей:** `SimilarPhotosView.swift`

#### 3.3. Screenshots (Скриншоты)
- **Алгоритм:** Фильтрация по медиатипу `.screenshot` через PhotoKit
- **Запрос:** `PHAsset.fetchAssets(with:)` с предикатом `mediaSubtype == .photoScreenshot`
- **Сервис:** `PhotoService.fetchScreenshots()`
- **Модель:** массив `PhotoAsset`
- **Экран деталей:** `ScreenshotsView.swift`

#### 3.4. Live Photos
- **Алгоритм:** Фильтрация по медиатипу Live Photo через PhotoKit
- **Запрос:** `PHAsset.fetchAssets(with:)` с предикатом `mediaSubtype == .photoLive`
- **Функция конвертации:** `PhotoService.convertLivePhotoToStill(_:)` — преобразование Live Photo в обычное фото (сохранение места)
- **Сервис:** `PhotoService.fetchLivePhotos()`
- **Экран деталей:** `LivePhotosView.swift`

#### 3.5. Burst Photos (Серийная съёмка)
- **Алгоритм:** Поиск по `burstIdentifier` через PhotoKit
- **Группировка:** По `burstIdentifier` — все фото серии в одной группе
- **Сервис:** `PhotoService.fetchBurstPhotos()`
- **Модель:** `BurstGroup`
- **Экран деталей:** `BurstPhotosView.swift`

#### 3.6. Big Files (Большие файлы)
- **Критерий:** Фото размером более определённого порога
- **Сортировка:** По размеру файла (от большего к меньшему)
- **Сервис:** Через `PhotoService` с фильтрацией по размеру
- **Экран деталей:** `BigFilesView.swift`

#### 3.7. Videos (Видео)
- **Категории:** Все видео, большие видео (>100MB), короткие видео (<10 сек)
- **Функция сжатия:** `VideoService.compressVideo(asset:quality:completion:)` через `AVAssetExportSession`
- **Качество сжатия:** `VideoCompressionQuality` enum (low, medium, high)
- **Сервис:** `VideoService.fetchAllVideos()`, `fetchLargeVideos()`, `fetchShortVideos()`
- **Экраны деталей:** `VideosView.swift`, `ShortVideosView.swift`

#### 3.8. Highlights (Избранные фото)
- **Алгоритм:** AI-lite подбор лучших фото на основе метаданных (избранные, с геолокацией, с лицами)
- **Сервис:** `PhotoService.findHighlights(limit:)`
- **Экран деталей:** `HighlightsView.swift`

### Блок 4: Быстрые действия

- **Кнопка "Scan"** — запуск полного сканирования
- **Навигация по категориям** — переход к детальному экрану категории при нажатии на карточку
- **Подсказки (Feature Tips)** — модальное окно с обучением при первом посещении

---

## Модель данных

```swift
struct PhotoAsset: Identifiable, Hashable {
    let id: String           // localIdentifier из PHAsset
    let asset: PHAsset       // оригинальный PHAsset
    let creationDate: Date?
    let fileSize: Int64      // размер в байтах
    let pixelWidth: Int
    let pixelHeight: Int
    var thumbnail: UIImage?  // кэшированная миниатюра
}

struct DuplicateGroup: Identifiable {
    let id: UUID
    var assets: [PhotoAsset] // минимум 2 фото
    var bestAsset: PhotoAsset // лучшее фото для сохранения
}

struct SimilarGroup: Identifiable {
    let id: UUID
    var assets: [PhotoAsset]
    var bestAsset: PhotoAsset
}

struct VideoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let duration: TimeInterval
    let fileSize: Int64
    var thumbnail: UIImage?
}

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64
    var usagePercentage: Double
}
```

---

## Жизненный цикл сканирования

1. **Запуск** → `DashboardViewModel.startScan()`
2. **Проверка кэша** → `ScanResultsCache.isCacheValid()` (TTL: 1 час)
3. **Если кэш валиден** → загрузка из кэша за ~100ms
4. **Если кэш невалиден** → полное сканирование:
   - Быстрый подсчёт (`updateQuickCounts()`) — скриншоты, Live Photos, видео
   - Сканирование дубликатов (`scanDuplicatesIfNeeded()`)
   - Сканирование похожих (`scanSimilarIfNeeded()`)
5. **Сохранение результатов** → `ScanResultsCache.saveResults()`
6. **Обновление UI** → `@Published` свойства обновляют SwiftUI views

---

## Ограничения (Freemium)

- Бесплатные пользователи: лимит 50 элементов в день
- При превышении лимита → показ `PremiumPaywallView`
- Проверка через `SubscriptionManager.canCleanItems(count:)`
- Учёт через `SubscriptionManager.recordCleanedItems(count:)`
