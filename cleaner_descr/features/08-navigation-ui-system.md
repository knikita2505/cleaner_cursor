# Функция: Навигация и UI-система

## Общее описание

Описание системы навигации, дизайн-системы (Theme) и переиспользуемых UI-компонентов, которые составляют фундамент визуального интерфейса приложения.

**Файлы реализации:**
- `Features/Main/MainTabView.swift` — корневой TabView (461 строка)
- `Core/Navigation/AppState.swift` — глобальное состояние (173 строки)
- `Core/Navigation/Router.swift` — координатор навигации
- `Core/Theme/` — дизайн-система (4 файла)
- `UI/Components/` — переиспользуемые компоненты (7 файлов)
- `Core/Extensions/View+Extensions.swift` — расширения View
- `Core/Utilities/HapticManager.swift` — тактильная обратная связь

---

## Блок 1: TabView (MainTabView)

### 5 вкладок

| Tab | Название | View | Иконка (SF Symbol) |
|-----|----------|------|---------------------|
| 0 | Hide | SecretSpaceHomeView | `lock.shield.fill` |
| 1 | Swipe | SwipeHubView | `hand.point.right.fill` |
| 2 | Clean | DashboardView | `sparkles` |
| 3 | Contacts | ContactsCleanerView | `person.crop.circle` |
| 4 | Analytics | CleaningHistoryView | `chart.bar.fill` |

### Внешний вид TabBar
```swift
func setupTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(AppColors.backgroundPrimary)
    
    // Цвета иконок
    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accentBlue)
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textTertiary)
    
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
```

### Swipe-навигация между вкладками
- `DragGesture` на контейнере
- Порог: 50pt горизонтального смещения
- `HapticManager.selection()` при переключении
- Программное изменение `AppState.shared.selectedTab`

---

## Блок 2: Navigation System

### AppState (Глобальное состояние)
```swift
class AppState: ObservableObject {
    static let shared = AppState()
    
    // Онбординг
    @Published var hasCompletedOnboarding: Bool  // UserDefaults
    @Published var hasCompletedPermissions: Bool // UserDefaults
    @Published var showSplash = true
    
    // Навигация
    @Published var selectedTab: AppTab = .clean
    @Published var dashboardPath = NavigationPath()
    @Published var photosPath = NavigationPath()
    
    // Разрешения
    @Published var showPermissionModal = false
    @Published var currentPermissionType: PermissionType?
}
```

### Router (Координатор)
```swift
class Router: ObservableObject {
    static let shared = Router()
    
    @Published var sheet: Sheet?
    @Published var fullScreenCover: FullScreenCover?
    
    func push<T: Hashable>(_ destination: T) { ... }
    func pop() { ... }
    func popToRoot() { ... }
    func present(_ sheet: Sheet) { ... }
    func presentFullScreen(_ cover: FullScreenCover) { ... }
}
```

### NavigationStack
- Каждая вкладка имеет свой `NavigationStack` с `NavigationPath`
- Destination определяются через `navigationDestination(for:)`
- Типы destination: `DashboardDestination`, `PhotosDestination`

---

## Блок 3: Дизайн-система (Theme)

### Цвета (AppColors)

#### Фоны
| Имя | Hex | Использование |
|-----|-----|---------------|
| `backgroundPrimary` | #0D0F16 | Основной фон экранов |
| `backgroundSecondary` | #111214 | Фон секций |
| `backgroundCard` | #121317 | Фон карточек |
| `backgroundModal` | #0F1116 | Фон модальных окон |

#### Акценты
| Имя | Hex | Использование |
|-----|-----|---------------|
| `accentBlue` | #3B5BFF | Основной акцент, CTA |
| `accentPurple` | #7A4DFB | Вторичный акцент |
| `accentLilac` | #A88CFF | Декоративный |
| `accentGlow` | #7FB9FF | Свечение |

#### Текст
| Имя | Hex | Использование |
|-----|-----|---------------|
| `textPrimary` | #FFFFFF | Заголовки |
| `textSecondary` | #E6E8ED | Подзаголовки |
| `textTertiary` | #AEB4BE | Вторичный текст |

#### Статусы
| Имя | Hex | Использование |
|-----|-----|---------------|
| `statusSuccess` | #41D3B3 | Успех |
| `statusWarning` | #FFB84D | Предупреждение |
| `statusError` | #FF4D4D | Ошибка |

#### Прогресс
| Имя | Hex | Использование |
|-----|-----|---------------|
| `progressStart` | #FF8D4D | Начало градиента прогресса |
| `progressEnd` | #FFD36B | Конец градиента прогресса |

### Шрифты (AppFonts) — SF Pro

| Стиль | Размер | Вес | Использование |
|-------|--------|-----|---------------|
| `largeTitle` | 34pt | Bold | Крупные заголовки |
| `titleXL` | 32pt | Bold | Заголовки экранов |
| `titleL` | 28pt | Bold | Секции |
| `titleM` | 24pt | Semibold | Подсекции |
| `subtitleL` | 18pt | Medium | Подзаголовки |
| `subtitleM` | 16pt | Medium | Малые подзаголовки |
| `bodyL` | 16pt | Regular | Основной текст |
| `bodyM` | 14pt | Regular | Вторичный текст |
| `caption` | 12pt | Regular | Подписи |
| `buttonPrimary` | 18pt | Medium | CTA кнопки |
| `buttonSecondary` | 16pt | Medium | Вторичные кнопки |

### Отступы (AppSpacing)

| Имя | Значение | Использование |
|-----|---------|---------------|
| `screenPadding` | 20pt | Горизонтальные отступы экрана |
| `screenPaddingLarge` | 24pt | Увеличенные отступы |
| `containerPadding` | 16pt | Padding внутри контейнеров |
| `blockSpacing` | 16pt | Между блоками |
| `cardRadius` | 20pt | Радиус карточек |
| `buttonRadius` | 16pt | Радиус кнопок |
| `modalRadius` | 32pt | Радиус модальных окон |
| `buttonHeight` | 56pt | Высота основных кнопок |

### Градиенты (AppGradients)

| Имя | Цвета | Использование |
|-----|-------|---------------|
| `ctaGradient` | #3B5BFF → #7A4DFB | CTA-кнопки |
| `auroraGradient` | #2F3DAF → #6B3BDB → #8B5CFF | Онбординг, фоны |
| `progressGradient` | #FF8D4D → #FFD36B | Прогресс-бары |
| `cardGradient` | #111214 → #0D0F16 | Карточки |
| `successGradient` | #41D3B3 → #2BA88E | Успех |
| `warningGradient` | #FFB84D → #FF8D4D | Предупреждение |

---

## Блок 4: UI-компоненты

### Кнопки (PrimaryButton.swift)

| Компонент | Описание | Размер |
|-----------|----------|--------|
| `PrimaryButton` | Основная CTA, градиентный фон | 56pt высота, 16pt радиус |
| `SecondaryButton` | Кнопка с обводкой | 48pt высота |
| `GhostButton` | Без фона, только текст | auto |
| `IconButton` | Только иконка | 44pt круг |
| `ScaleButtonStyle` | Анимация нажатия (scaleEffect 0.95-0.97) | — |

### Карточки (PrimaryCard.swift)

| Компонент | Описание | Размер |
|-----------|----------|--------|
| `PrimaryCard` | Основная карточка с иконкой и стрелкой | auto |
| `ListCard` | Строка списка | 72-80pt высота |
| `StatsCard` | Статистика (число + единица) | auto |

### Модальные окна (StandardModal.swift)

| Компонент | Описание | Радиус |
|-----------|----------|--------|
| `StandardModal` | Стандартное модальное окно | 32pt |
| `PermissionModal` | Запрос разрешения | 32pt |
| `AlertModal` | Предупреждение/ошибка | 32pt |
| `ModalOverlay` | Затемнённый оверлей | — |

### Прогресс (ProgressBars.swift)

| Компонент | Описание |
|-----------|----------|
| `StorageProgressBar` | Горизонтальный бар хранилища с градиентом |
| `AccentProgressBar` | Горизонтальный бар с акцентным цветом |
| `CircularProgress` | Круговой индикатор с процентом |
| `SegmentedProgress` | Сегменты для онбординга |
| `DotProgress` | Точки для пагинации |

### Фоны (GradientBackgrounds.swift)

| Компонент | Описание |
|-----------|----------|
| `AuroraBackground` | Анимированный градиент для онбординга/paywall |
| `DarkGradientBackground` | Простой тёмный градиент |
| `MeshBackground` | Mesh-градиент для премиум (iOS 18+) |
| `ParticleBackground` | Анимированные частицы |

### Состояния (EmptyState.swift)

| Компонент | Описание |
|-----------|----------|
| `EmptyStateView` | Пустой список (иконка + текст + кнопка) |
| `SuccessStateView` | Успешная операция (статистика) |
| `LoadingStateView` | Загрузка (индикатор/прогресс) |
| `ErrorStateView` | Ошибка (кнопка повтора) |

---

## Блок 5: View Extensions

### Модификаторы
```swift
extension View {
    func cardStyle() -> some View         // Стиль карточки (фон, тень, радиус)
    func shimmer() -> some View           // Shimmer-эффект при загрузке
    func fadeEdge(_ edge: Edge, length: CGFloat) -> some View  // Затухание краёв
    func hideKeyboard()                   // Скрыть клавиатуру
    func readSize(onChange:) -> some View  // Чтение размера view
    func `if`<Content: View>(_ condition: Bool, transform: ...) -> some View  // Условный модификатор
}
```

---

## Блок 6: Haptic Feedback (HapticManager)

```swift
enum HapticManager {
    static func lightImpact()       // Лёгкое нажатие
    static func mediumImpact()      // Среднее нажатие
    static func heavyImpact()       // Сильное нажатие
    static func success()           // Успех (notification)
    static func warning()           // Предупреждение
    static func error()             // Ошибка
    static func selection()         // Выбор элемента
}
```

**Использование:**
- Переключение вкладок → `selection()`
- Успешное удаление → `success()`
- Ошибка → `error()`
- Свайп фото → `lightImpact()`
- Нажатие CTA → `mediumImpact()`
