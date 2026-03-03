# Функция: Device Health — Здоровье устройства

## Общее описание

Device Health — модуль мониторинга состояния устройства. Оценивает здоровье по четырём параметрам (хранилище, батарея, производительность, температура) и выдаёт общий health score. Предоставляет советы по оптимизации.

**Вкладка:** Analytics (часть вкладки, доступна через навигацию)

**Файлы реализации:**
- `Features/DeviceHealth/Views/DeviceHealthView.swift` — главный экран
- `Features/DeviceHealth/Views/BatteryInsightsView.swift` — инсайты по батарее
- `Features/DeviceHealth/Views/SystemTipsView.swift` — системные советы
- `Core/Services/DeviceHealthService.swift` — расчёт оценок
- `Core/Services/BatteryService.swift` — мониторинг батареи
- `Core/Services/StorageService.swift` — информация о хранилище

---

## Блоки функции

### Блок 1: Health Score (Общая оценка)

**Что отображает:**
- Круговой индикатор с общей оценкой (0-100)
- Цветовая индикация: зелёный (>75), жёлтый (50-75), красный (<50)
- Текстовый статус: "Excellent", "Good", "Fair", "Poor"

**Алгоритм расчёта:**
```swift
enum HealthStatus {
    case excellent  // score > 85
    case good       // score > 70
    case fair       // score > 50
    case poor       // score <= 50
}

// Общий score = средневзвешенное 4 категорий
let overallScore = (storageScore * 0.3 + batteryScore * 0.3 + 
                    performanceScore * 0.2 + temperatureScore * 0.2)
```

### Блок 2: Storage Score (Оценка хранилища)

**Алгоритм:**
- 100% свободно → 100 баллов
- 0% свободно → 0 баллов
- Линейная интерполяция
- Штраф при <10% свободного места

**Источник данных:** `StorageService.shared`

### Блок 3: Battery Score (Оценка батареи)

**Параметры:**
- Уровень заряда (batteryLevel: 0.0...1.0)
- Состояние зарядки (batteryState: .charging, .full, .unplugged)
- Low Power Mode (isLowPowerModeEnabled)

**Алгоритм:**
```swift
func calculateBatteryScore() -> Int {
    let level = UIDevice.current.batteryLevel  // 0.0 - 1.0
    var score = Int(level * 100)
    
    // Бонус за зарядку
    if UIDevice.current.batteryState == .charging { score = min(100, score + 10) }
    
    // Штраф за Low Power Mode (устройство уже экономит)
    if ProcessInfo.processInfo.isLowPowerModeEnabled { score = max(0, score - 5) }
    
    return score
}
```

**Статус здоровья батареи:**
```swift
enum BatteryHealthStatus {
    case excellent  // > 80%
    case good       // > 50%
    case fair       // > 20%
    case poor       // <= 20%
}
```

**Советы по батарее:**
- Динамически генерируемые советы на основе текущего состояния
- Модель `BatteryTip(id, icon, title, description)`
- Примеры: "Включите Low Power Mode", "Уменьшите яркость"

### Блок 4: Performance Score (Оценка производительности)

**Алгоритм:**
- На основе uptime устройства (`ProcessInfo.processInfo.systemUptime`)
- Долгий uptime → рекомендация перезагрузить
- <24h → 100 баллов
- >7 дней → 60 баллов

### Блок 5: Temperature Score (Оценка температуры)

**Алгоритм:**
- `ProcessInfo.processInfo.thermalState`
- `.nominal` → 100 баллов
- `.fair` → 75 баллов
- `.serious` → 40 баллов
- `.critical` → 10 баллов

### Блок 6: System Tips (Системные советы)

**Контекстные советы:**
- Генерируются на основе текущих оценок
- Приоритезация по серьёзности проблемы
- Пример: "Free up storage — you have less than 10% free"
- Пример: "Restart your device — it's been running for 7 days"

---

## Мониторинг в реальном времени

**BatteryService использует NotificationCenter:**
```swift
NotificationCenter.default.addObserver(
    forName: UIDevice.batteryLevelDidChangeNotification, ...
)
NotificationCenter.default.addObserver(
    forName: UIDevice.batteryStateDidChangeNotification, ...
)
NotificationCenter.default.addObserver(
    forName: ProcessInfo.thermalStateDidChangeNotification, ...
)
```

**Обновление:** Данные обновляются при каждом входе на экран и при изменении состояния батареи/температуры.

---

## Модель категорий

```swift
enum CategoryStatus {
    case excellent   // зелёный кружок
    case good        // зелёный кружок
    case warning     // жёлтый кружок
    case critical    // красный кружок
    
    var color: Color { ... }
    var icon: String { ... }   // SF Symbol
}
```

---

## Ограничения (Freemium)

- Базовый Health Score — бесплатно
- Детальные инсайты и советы — могут требовать премиум
