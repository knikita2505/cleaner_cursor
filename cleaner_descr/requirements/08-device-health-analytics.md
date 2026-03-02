# Требования: Device Health и аналитика очисток

## Цель
Реализовать мониторинг состояния устройства и историю очисток с визуальными графиками и рекомендациями.

---

## Требование 1: DeviceHealthService

### Класс
```swift
@MainActor
class DeviceHealthService: ObservableObject {
    static let shared = DeviceHealthService()
    
    @Published var overallScore: Int = 0
    @Published var storageScore: Int = 0
    @Published var batteryScore: Int = 0
    @Published var performanceScore: Int = 0
    @Published var temperatureScore: Int = 0
    @Published var healthStatus: HealthStatus = .good
    @Published var isRefreshing = false
}
```

### Алгоритм расчёта Health Score
```swift
func calculateScores() {
    storageScore = calculateStorageScore()
    batteryScore = calculateBatteryScore()
    performanceScore = calculatePerformanceScore()
    temperatureScore = calculateTemperatureScore()
    
    overallScore = Int(
        Double(storageScore) * 0.3 +
        Double(batteryScore) * 0.3 +
        Double(performanceScore) * 0.2 +
        Double(temperatureScore) * 0.2
    )
    
    healthStatus = HealthStatus(score: overallScore)
}

// Storage: линейная шкала по % свободного места
func calculateStorageScore() -> Int {
    let info = StorageService.shared.storageInfo
    let freePercentage = Double(info.freeSpace) / Double(info.totalSpace)
    if freePercentage < 0.05 { return 10 }       // <5% — критично
    if freePercentage < 0.10 { return 30 }       // <10%
    if freePercentage < 0.20 { return 50 }       // <20%
    if freePercentage < 0.40 { return 75 }       // <40%
    return min(100, Int(freePercentage * 120))    // >40%
}

// Battery: уровень заряда + бонусы/штрафы
func calculateBatteryScore() -> Int {
    var score = Int(UIDevice.current.batteryLevel * 100)
    if UIDevice.current.batteryState == .charging { score = min(100, score + 10) }
    if ProcessInfo.processInfo.isLowPowerModeEnabled { score = max(0, score - 5) }
    return max(0, min(100, score))
}

// Performance: на основе uptime
func calculatePerformanceScore() -> Int {
    let uptime = ProcessInfo.processInfo.systemUptime
    let days = uptime / 86400
    if days < 1 { return 100 }
    if days < 3 { return 85 }
    if days < 7 { return 70 }
    return 60
}

// Temperature: на основе thermal state
func calculateTemperatureScore() -> Int {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: return 100
    case .fair: return 75
    case .serious: return 40
    case .critical: return 10
    @unknown default: return 50
    }
}
```

### Перечисления
```swift
enum HealthStatus {
    case excellent   // > 85
    case good        // > 70
    case fair        // > 50
    case poor        // <= 50
    
    init(score: Int) {
        if score > 85 { self = .excellent }
        else if score > 70 { self = .good }
        else if score > 50 { self = .fair }
        else { self = .poor }
    }
    
    var title: String { ... }
    var color: Color { ... }
    var icon: String { ... }
}

enum CategoryStatus {
    case excellent, good, warning, critical
    
    init(score: Int) {
        if score > 80 { self = .excellent }
        else if score > 60 { self = .good }
        else if score > 40 { self = .warning }
        else { self = .critical }
    }
    
    var color: Color { ... }
}
```

---

## Требование 2: BatteryService

### Класс
```swift
@MainActor
class BatteryService: ObservableObject {
    static let shared = BatteryService()
    
    @Published var batteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isLowPowerMode: Bool = false
    @Published var healthStatus: BatteryHealthStatus = .good
    @Published var tips: [BatteryTip] = []
}
```

### Мониторинг
```swift
func setupBatteryMonitoring() {
    UIDevice.current.isBatteryMonitoringEnabled = true
    
    NotificationCenter.default.addObserver(
        forName: UIDevice.batteryLevelDidChangeNotification,
        object: nil, queue: .main
    ) { [weak self] _ in
        self?.updateBatteryInfo()
    }
    
    NotificationCenter.default.addObserver(
        forName: UIDevice.batteryStateDidChangeNotification,
        object: nil, queue: .main
    ) { [weak self] _ in
        self?.updateBatteryInfo()
    }
    
    NotificationCenter.default.addObserver(
        forName: .NSProcessInfoPowerStateDidChange,
        object: nil, queue: .main
    ) { [weak self] _ in
        self?.updateBatteryInfo()
    }
    
    updateBatteryInfo()
}
```

### Советы по батарее
```swift
struct BatteryTip: Identifiable {
    let id: UUID
    let icon: String        // SF Symbol
    let title: String
    let description: String
}

var tips: [BatteryTip] {
    var tips: [BatteryTip] = []
    
    if batteryLevel < 0.2 && batteryState != .charging {
        tips.append(BatteryTip(icon: "bolt.fill", title: "Low Battery", 
                              description: "Connect your device to a charger"))
    }
    
    if !isLowPowerMode && batteryLevel < 0.5 {
        tips.append(BatteryTip(icon: "battery.25", title: "Enable Low Power Mode",
                              description: "Extend battery life"))
    }
    
    // ... больше советов на основе текущего состояния
    return tips
}
```

---

## Требование 3: StorageService

### Класс
```swift
@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var storageInfo = StorageInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
}
```

### Получение данных
```swift
func refreshStorageInfo() {
    guard let attrs = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
    ) else { return }
    
    let total = attrs[.systemSize] as? Int64 ?? 0
    let free = attrs[.systemFreeSize] as? Int64 ?? 0
    let used = total - free
    
    storageInfo = StorageInfo(totalSpace: total, usedSpace: used, freeSpace: free)
}

static func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
```

---

## Требование 4: CleaningHistoryService

### Класс
```swift
@MainActor
class CleaningHistoryService: ObservableObject {
    static let shared = CleaningHistoryService()
    
    @Published var records: [CleaningRecord] = []
    @Published var summary: CleaningSummary = .empty
    @Published var weeklyData: [DailyCleaningData] = []
}
```

### Модели
```swift
struct CleaningRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: CleaningType
    let itemsCount: Int
    let bytesFreed: Int64
}

enum CleaningType: String, Codable, CaseIterable {
    case duplicatePhotos, similarPhotos, screenshots, livePhotos
    case burstPhotos, largePhotos, videos, contacts, other
    
    var displayName: String { ... }
    var color: Color { ... }
    var icon: String { ... }    // SF Symbol
}

struct CleaningSummary {
    let totalItems: Int
    let totalBytes: Int64
    let todayItems: Int
    let todayBytes: Int64
    let weekItems: Int
    let weekBytes: Int64
    let monthItems: Int
    let monthBytes: Int64
    
    static let empty = CleaningSummary(...)
}

struct DailyCleaningData: Identifiable {
    let id: UUID
    let date: Date
    let weekday: String         // "Mon", "Tue", ...
    let itemsCount: Int
}

struct PieChartSegment: Identifiable {
    let id: UUID
    let type: CleaningType
    let count: Int
    let percentage: Double
    let color: Color
}

struct CleaningRecommendation: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let priority: RecommendationPriority
    let icon: String
}

enum RecommendationPriority {
    case high, medium, low
    var color: Color { ... }
}
```

### Запись
```swift
func recordCleaning(type: CleaningType, itemsCount: Int, bytesFreed: Int64) {
    let record = CleaningRecord(
        id: UUID(), date: Date(), type: type,
        itemsCount: itemsCount, bytesFreed: bytesFreed
    )
    records.append(record)
    
    // Удалить записи старше 6 месяцев
    let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
    records = records.filter { $0.date > sixMonthsAgo }
    
    saveRecords()
    updateSummary()
}
```

### Графики

#### Weekly Bar Chart
```swift
func getWeeklyData() -> [DailyCleaningData] {
    let calendar = Calendar.current
    let today = Date()
    var data: [DailyCleaningData] = []
    
    for dayOffset in (0..<7).reversed() {
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let count = records.filter { $0.date >= dayStart && $0.date < dayEnd }
            .reduce(0) { $0 + $1.itemsCount }
        
        let weekday = DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
        data.append(DailyCleaningData(id: UUID(), date: date, weekday: weekday, itemsCount: count))
    }
    
    return data
}
```

#### Pie Chart
```swift
func getPieChartData() -> [PieChartSegment] {
    let monthRecords = records.filter { $0.date.isThisMonth }
    let total = monthRecords.reduce(0) { $0 + $1.itemsCount }
    guard total > 0 else { return [] }
    
    var segments: [PieChartSegment] = []
    for type in CleaningType.allCases {
        let count = monthRecords.filter { $0.type == type }.reduce(0) { $0 + $1.itemsCount }
        if count > 0 {
            segments.append(PieChartSegment(
                id: UUID(), type: type, count: count,
                percentage: Double(count) / Double(total) * 100,
                color: type.color
            ))
        }
    }
    
    return segments.sorted { $0.count > $1.count }
}
```

#### Рекомендации
```swift
func getRecommendations() -> [CleaningRecommendation] {
    var recs: [CleaningRecommendation] = []
    
    // 1. Давно не сканировали
    if records.isEmpty || !records.contains(where: { $0.date.isThisWeek }) {
        recs.append(CleaningRecommendation(
            title: "Run a scan", description: "Scan your device for junk files",
            priority: .high, icon: "magnifyingglass"
        ))
    }
    
    // 2. Много дубликатов
    if PhotoService.shared.duplicateGroups.count > 5 {
        recs.append(CleaningRecommendation(
            title: "Clean duplicates", 
            description: "\(PhotoService.shared.duplicateGroups.count) groups found",
            priority: .high, icon: "doc.on.doc"
        ))
    }
    
    // 3. Много скриншотов
    if PhotoService.shared.screenshotCount > 50 {
        recs.append(CleaningRecommendation(
            title: "Review screenshots",
            description: "\(PhotoService.shared.screenshotCount) screenshots found",
            priority: .medium, icon: "camera.viewfinder"
        ))
    }
    
    return recs
}
```

---

## Требование 5: UI экраны

### DeviceHealthView
- Круговой индикатор Health Score (большой, по центру)
- 4 карточки категорий (Storage, Battery, Performance, Temperature)
- Цветовая индикация для каждой категории
- Кнопка "Refresh"

### BatteryInsightsView
- Уровень заряда (большое число)
- Состояние (Charging / Not Charging)
- Low Power Mode статус
- Список советов (BatteryTip)

### CleaningHistoryView
- Summary Cards (Today, Week, Month, Total)
- Weekly Bar Chart (7 столбцов)
- Monthly Pie Chart (круговая диаграмма)
- Список рекомендаций
- Кнопка "Clear History"

---

## Требование 6: Уведомления (NotificationService)

### Класс
```swift
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isEnabled: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
}
```

### Планирование
```swift
func scheduleNotifications() {
    // Планировать на 14 дней вперёд
    // Два уведомления в день: утром (9:00) и вечером (19:00)
    // 12 вариантов текстов, ротация
    
    let texts = [
        ("Time to clean!", "Your phone has accumulated junk files. Clean now!"),
        ("Storage getting full?", "Free up space with a quick scan"),
        // ... 10 больше вариантов
    ]
    
    for day in 0..<14 {
        for (hour, minute) in [(9, 0), (19, 0)] {
            let content = UNMutableNotificationContent()
            let text = texts[(day * 2 + (hour == 19 ? 1 : 0)) % texts.count]
            content.title = text.0
            content.body = text.1
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let targetDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
            dateComponents.day = Calendar.current.component(.day, from: targetDate)
            dateComponents.month = Calendar.current.component(.month, from: targetDate)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "clean_\(day)_\(hour)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
```

---

## Критерии приёмки

- [ ] Health Score рассчитывается из 4 компонентов с весами
- [ ] Battery мониторинг обновляется в реальном времени
- [ ] Storage информация получается через FileManager
- [ ] CleaningHistory записывается при каждой очистке
- [ ] Weekly Chart показывает данные за 7 дней
- [ ] Pie Chart показывает распределение по типам
- [ ] Рекомендации генерируются динамически
- [ ] Уведомления планируются на 14 дней
- [ ] Данные истории хранятся 6 месяцев (автоочистка)
