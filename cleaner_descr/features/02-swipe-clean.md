# Функция: Swipe Clean — Быстрая очистка фото свайпами

## Общее описание

Swipe Clean — Tinder-подобный интерфейс для быстрой сортировки фотографий по месяцам. Пользователь свайпает фото влево (удалить) или вправо (оставить), проходя всю фотобиблиотеку месяц за месяцем.

**Вкладка:** Swipe (вторая вкладка TabView)

**Файлы реализации:**
- `Features/Swipe/Views/SwipeHubView.swift` — экран выбора месяца
- `Features/Swipe/Views/SwipeSessionView.swift` — сессия свайп-очистки
- `Core/Services/SwipeProgressService.swift` — хранение прогресса
- `Core/Services/PhotoService.swift` — получение фото

---

## Блоки функции

### Блок 1: Swipe Hub (Выбор месяца)

**Что отображает:**
- Список месяцев с фотографиями (от новых к старым)
- Для каждого месяца: название, количество фото, прогресс просмотра (%), превью
- Общий прогресс по всем месяцам
- Кнопка начала/продолжения сессии

**Техническая реализация:**
- `SwipeHubViewModel` — загрузка списка месяцев через PhotoKit
- `PhotoMonthGroup` — группировка PHAsset по месяцам (Calendar.current.component)
- `SwipeProgressService.getProgress(for:)` — получение прогресса для каждого месяца
- `MonthProgress` — модель прогресса: reviewed, deleted, kept, total

**Модель данных:**
```swift
struct PhotoMonthGroup: Identifiable, Hashable {
    let id: String              // формат "2024-01"
    let month: Date
    let assets: [PHAsset]
    var displayName: String     // "January 2024"
}

struct MonthProgress: Codable, Identifiable {
    let monthKey: String
    var totalCount: Int
    var reviewedCount: Int
    var deletedCount: Int
    var keptCount: Int
    var reviewedPhotoIds: Set<String>
    var deletedPhotoIds: Set<String>
    var keptPhotoIds: Set<String>
    
    var progressPercentage: Double  // computed
    var isComplete: Bool            // computed
}
```

### Блок 2: Swipe Session (Сессия очистки)

**Что отображает:**
- Текущая фотография на весь экран
- Индикаторы свайпа: зелёная рамка (keep) / красная рамка (delete)
- Прогресс-бар текущей сессии
- Счётчик: X / Y фото
- Кнопка отмены последнего действия (undo)

**Механика свайпа:**
- **Свайп вправо** → фото помечается как "оставить" (keep)
- **Свайп влево** → фото помечается как "удалить" (delete)
- **Свайп вверх** (опционально) → пропуск
- Анимация карточки при свайпе (rotation + translation)
- Haptic feedback при свайпе

**Техническая реализация:**
- `SwipeSessionViewModel` — управление текущей сессией
- `DragGesture` для обработки свайпов
- Порог срабатывания: ~100 pt смещения
- Предзагрузка следующих 3-5 фото для плавности
- `PHCachingImageManager` для кэширования миниатюр
- `SwipeProgressService.updateProgress(monthKey:photoId:decision:)` — сохранение решения

**Логика удаления:**
- Фото не удаляются мгновенно — копятся в массив `deletedPhotoIds`
- По завершении сессии (или по нажатию кнопки) — batch-удаление через `PHPhotoLibrary.shared().performChanges`
- Проверка лимита подписки перед удалением: `SubscriptionManager.canCleanItems(count:)`

### Блок 3: Прогресс и статистика

**Что хранится:**
- Прогресс по каждому месяцу (reviewed/deleted/kept)
- ID просмотренных фото для исключения из повторного показа
- Общий процент прогресса по всей библиотеке

**Персистентность:**
- `SwipeProgressService` хранит данные в `UserDefaults`
- Ключ: `"swipe_progress_\(monthKey)"`
- Данные кодируются в JSON через `Codable`

**Функция отмены (Undo):**
- `SwipeProgressService.undoLastDecision(monthKey:)` — отмена последнего решения
- Возврат фото обратно в стек для повторного показа
- Обновление счётчиков reviewed/deleted/kept

---

## Алгоритм работы сессии

1. Пользователь выбирает месяц в SwipeHub
2. Загружаются все фото месяца через PhotoKit
3. Отфильтровываются уже просмотренные (по `reviewedPhotoIds`)
4. Фото отображаются по одному с возможностью свайпа
5. Каждое решение сохраняется в `SwipeProgressService`
6. По завершении — предложение удалить помеченные фото
7. Перед удалением — проверка лимита подписки
8. Batch-удаление через PhotoKit
9. Запись в `CleaningHistoryService`

---

## Ограничения (Freemium)

- Просмотр и свайп фото — бесплатно (без лимита)
- Удаление — в рамках дневного лимита 50 элементов
- При превышении → `PremiumPaywallView`
