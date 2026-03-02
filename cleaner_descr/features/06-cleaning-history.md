# Функция: Cleaning History — Аналитика очисток

## Общее описание

Cleaning History — модуль аналитики и статистики по очисткам. Отображает историю очисток за день/неделю/месяц, визуальные графики (столбчатые и круговые), рекомендации по дальнейшей очистке.

**Вкладка:** Analytics (пятая вкладка TabView, основной экран)

**Файлы реализации:**
- `Features/CleaningHistory/Views/CleaningHistoryView.swift` — экран аналитики
- `Core/Services/CleaningHistoryService.swift` — сервис истории

---

## Блоки функции

### Блок 1: Summary Cards (Сводные карточки)

**Что отображает:**
- "Today" — количество очищенных элементов сегодня + размер
- "This Week" — за неделю
- "This Month" — за месяц
- "Total" — за всё время

**Модель данных:**
```swift
struct CleaningSummary {
    let totalItems: Int       // общее количество очищенных элементов
    let totalBytes: Int64     // общий размер освобождённого места
    let todayItems: Int
    let todayBytes: Int64
    let weekItems: Int
    let weekBytes: Int64
    let monthItems: Int
    let monthBytes: Int64
}
```

### Блок 2: Weekly Bar Chart (Столбчатый график)

**Что отображает:**
- 7 столбцов (по дням недели: Mon–Sun)
- Высота столбца = количество очищенных элементов в этот день
- Цвет: градиент из дизайн-системы
- При нажатии на столбец — tooltip с детальной информацией

**Техническая реализация:**
- `CleaningHistoryService` фильтрует записи за текущую неделю
- Группировка по `Calendar.current.component(.weekday, from: date)`
- Нормализация высоты столбцов относительно максимума
- Кастомная SwiftUI view без использования Charts framework

### Блок 3: Monthly Pie Chart (Круговая диаграмма)

**Что отображает:**
- Сегменты по типам очистки (фото, видео, контакты, скриншоты и т.д.)
- Процент каждого типа от общего
- Легенда с цветами и процентами

**Модель данных:**
```swift
struct PieChartSegment: Identifiable {
    let id: UUID
    let type: CleaningType
    let count: Int
    let percentage: Double
    let color: Color
}

enum CleaningType: String, Codable, CaseIterable {
    case duplicatePhotos = "Duplicate Photos"
    case similarPhotos = "Similar Photos"
    case screenshots = "Screenshots"
    case livePhotos = "Live Photos"
    case burstPhotos = "Burst Photos"
    case largePhotos = "Large Photos"
    case videos = "Videos"
    case contacts = "Contacts"
    case other = "Other"
    
    var color: Color { ... }
    var icon: String { ... }
}
```

### Блок 4: Recommendations (Рекомендации)

**Что отображает:**
- Динамические рекомендации на основе текущего состояния
- Приоритет: high, medium, low
- Кнопка перехода к соответствующей функции

**Алгоритм генерации:**
```swift
func getRecommendations() -> [CleaningRecommendation] {
    var recommendations: [CleaningRecommendation] = []
    
    // Если давно не сканировали
    if lastScanDate == nil || daysSinceLastScan > 7 {
        recommendations.append(.init(
            title: "Run a scan",
            description: "It's been a while since your last scan",
            priority: .high,
            action: .navigateToClean
        ))
    }
    
    // Если много дубликатов
    if PhotoService.shared.duplicateGroups.count > 10 {
        recommendations.append(.init(
            title: "Clean duplicate photos",
            description: "\(count) duplicate groups found",
            priority: .high,
            action: .navigateToDuplicates
        ))
    }
    
    // ... другие правила
}
```

**Модель:**
```swift
struct CleaningRecommendation: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let priority: RecommendationPriority
    let icon: String
    let action: RecommendationAction
}

enum RecommendationPriority {
    case high, medium, low
    var color: Color { ... }
}
```

### Блок 5: Clear History

- Кнопка "Clear All History" — удаление всей истории
- Подтверждение через AlertModal
- `CleaningHistoryService.clearAllHistory()`

---

## Запись в историю

Каждое действие по очистке записывается в `CleaningHistoryService`:
```swift
struct CleaningRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: CleaningType
    let itemsCount: Int
    let bytesFreed: Int64
}
```

**Вызов при очистке:**
```swift
CleaningHistoryService.shared.recordCleaning(
    type: .duplicatePhotos,
    itemsCount: deletedCount,
    bytesFreed: totalBytesFreed
)
```

**Хранение:** UserDefaults (ключ: `"cleaning_history"`, JSON-encoded, последние 6 месяцев)

---

## Ограничения (Freemium)

- Просмотр аналитики — только для премиум-пользователей
- При отсутствии подписки → `PremiumPaywallView`
