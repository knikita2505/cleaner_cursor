# Требования: Swipe Clean

## Цель
Реализовать Tinder-подобный интерфейс для быстрой сортировки фотографий по месяцам со свайп-жестами.

---

## Требование 1: SwipeProgressService

### Класс
```swift
class SwipeProgressService: ObservableObject {
    static let shared = SwipeProgressService()
    
    @Published var monthProgressMap: [String: MonthProgress] = [:]
}
```

### Модели
```swift
struct MonthProgress: Codable, Identifiable {
    let monthKey: String          // "2024-01"
    var totalCount: Int
    var reviewedCount: Int
    var deletedCount: Int
    var keptCount: Int
    var reviewedPhotoIds: Set<String>
    var deletedPhotoIds: Set<String>
    var keptPhotoIds: Set<String>
    
    var id: String { monthKey }
    var progressPercentage: Double { 
        totalCount == 0 ? 0 : Double(reviewedCount) / Double(totalCount) * 100 
    }
    var isComplete: Bool { reviewedCount >= totalCount }
}

enum SwipeDecision {
    case keep
    case delete
}

struct PhotoMonthGroup: Identifiable, Hashable {
    let id: String                // "2024-01"
    let month: Date
    let assets: [PHAsset]
    var displayName: String       // "January 2024"
}
```

### Методы
```swift
func getProgress(for monthKey: String) -> MonthProgress
func updateProgress(monthKey: String, photoId: String, decision: SwipeDecision)
func setTotalCount(monthKey: String, total: Int)
func resetProgress(for monthKey: String)
func undoLastDecision(monthKey: String)
func isPhotoReviewed(monthKey: String, photoId: String) -> Bool
func getTotalProgress() -> Double  // Общий % по всем месяцам
```

### Хранение
- UserDefaults: `"swipe_progress_\(monthKey)"` для каждого месяца
- JSON-кодирование через `Codable`

---

## Требование 2: SwipeHubView

### UI
- Вертикальный список месяцев (ScrollView + LazyVStack)
- Каждая строка содержит:
  - Превью фото (первое фото месяца, миниатюра)
  - Название месяца ("January 2024")
  - Количество фото
  - Прогресс-бар (AccentProgressBar)
  - Процент просмотренных
- Кнопка "Start" / "Continue" для каждого месяца
- Общий прогресс вверху экрана

### ViewModel
```swift
@MainActor
class SwipeHubViewModel: ObservableObject {
    @Published var monthGroups: [PhotoMonthGroup] = []
    @Published var isLoading = true
    
    func loadMonths() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        // Группировка по месяцам
        var groups: [String: [PHAsset]] = [:]
        result.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            let key = monthKey(from: date)  // "2024-01"
            groups[key, default: []].append(asset)
        }
        
        monthGroups = groups.map { PhotoMonthGroup(id: $0.key, month: ..., assets: $0.value) }
            .sorted { $0.month > $1.month }
    }
}
```

---

## Требование 3: SwipeSessionView

### Механика свайпа
```swift
struct SwipeSessionView: View {
    @State private var offset: CGSize = .zero
    @State private var currentIndex: Int = 0
    
    var body: some View {
        ZStack {
            // Текущая фотокарточка
            photoCard
                .offset(offset)
                .rotationEffect(.degrees(Double(offset.width / 20)))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                // Свайп вправо → KEEP
                                handleDecision(.keep)
                            } else if value.translation.width < -100 {
                                // Свайп влево → DELETE
                                handleDecision(.delete)
                            } else {
                                // Вернуть на место
                                withAnimation(.spring()) { offset = .zero }
                            }
                        }
                )
        }
    }
}
```

### Индикаторы свайпа
- При смещении вправо: зелёная рамка + текст "KEEP" + иконка checkmark
- При смещении влево: красная рамка + текст "DELETE" + иконка trash
- Opacity пропорциональна смещению (0 → 1 при 100pt)

### Предзагрузка
```swift
// Предзагрузить миниатюры для следующих 3-5 фото
func prefetchThumbnails() {
    let upcoming = assets[currentIndex..<min(currentIndex + 5, assets.count)]
    let size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    imageManager.startCachingImages(for: Array(upcoming), targetSize: size, contentMode: .aspectFill, options: nil)
}
```

### Undo (отмена)
```swift
func undo() {
    guard currentIndex > 0 else { return }
    let previousPhotoId = assets[currentIndex - 1].localIdentifier
    SwipeProgressService.shared.undoLastDecision(monthKey: monthKey)
    currentIndex -= 1
    HapticManager.lightImpact()
}
```

### Завершение сессии
```swift
func finishSession() {
    let deletedAssets = assets.filter { 
        progress.deletedPhotoIds.contains($0.localIdentifier) 
    }
    
    if deletedAssets.isEmpty { 
        // Нечего удалять, показать SuccessStateView
        return 
    }
    
    // Проверить лимит подписки
    let permission = SubscriptionManager.shared.canCleanItems(count: deletedAssets.count)
    
    switch permission {
    case .allowed:
        Task {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(deletedAssets as NSArray)
            }
            SubscriptionManager.shared.recordCleanedItems(count: deletedAssets.count)
            CleaningHistoryService.shared.recordCleaning(
                type: .other, itemsCount: deletedAssets.count, bytesFreed: 0
            )
        }
    case .limitReached:
        SubscriptionManager.shared.showPaywall(for: .reachedLimits)
    }
}
```

---

## Требование 4: UI элементы

### Карточка фото
- Полноэкранное фото (с отступами)
- Скруглённые углы (20pt)
- Тень
- Дата создания внизу карточки
- Размер файла

### Прогресс-бар сессии
- Горизонтальный бар вверху экрана
- Отображает: X / Y фото
- Градиент: progressGradient

### Кнопки управления
- Кнопка Undo (стрелка назад)
- Кнопка Delete (красная, trash icon)
- Кнопка Keep (зелёная, checkmark icon)
- Для пользователей, предпочитающих нажатия вместо свайпов

---

## Критерии приёмки

- [ ] Список месяцев загружается из PhotoKit
- [ ] Прогресс сохраняется между сессиями
- [ ] Свайп вправо = keep, влево = delete
- [ ] Анимация поворота и смещения карточки
- [ ] Индикаторы KEEP/DELETE видны при свайпе
- [ ] Haptic feedback при свайпе
- [ ] Undo отменяет последнее действие
- [ ] Предзагрузка миниатюр для плавности
- [ ] Batch-удаление при завершении сессии
- [ ] Проверка лимита подписки
