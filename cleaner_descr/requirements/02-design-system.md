# Требования: Дизайн-система

## Цель
Создать единую дизайн-систему (Theme), которая обеспечивает консистентный визуальный стиль всего приложения.

---

## Требование 1: Цвета (AppColors.swift)

Создать `enum AppColors` со статическими свойствами типа `Color`:

### Фоны
```swift
enum AppColors {
    static let backgroundPrimary = Color(hex: "0D0F16")    // Основной фон
    static let backgroundSecondary = Color(hex: "111214")  // Фон секций
    static let backgroundCard = Color(hex: "121317")       // Фон карточек
    static let backgroundModal = Color(hex: "0F1116")      // Фон модалок
    
    // Акценты
    static let accentBlue = Color(hex: "3B5BFF")           // Основной акцент
    static let accentPurple = Color(hex: "7A4DFB")         // Вторичный акцент
    static let accentLilac = Color(hex: "A88CFF")          // Декоративный
    static let accentGlow = Color(hex: "7FB9FF")           // Свечение
    
    // Текст
    static let textPrimary = Color.white                   // Заголовки
    static let textSecondary = Color(hex: "E6E8ED")        // Подзаголовки
    static let textTertiary = Color(hex: "AEB4BE")         // Вторичный
    
    // Статусы
    static let statusSuccess = Color(hex: "41D3B3")
    static let statusWarning = Color(hex: "FFB84D")
    static let statusError = Color(hex: "FF4D4D")
    
    // Прогресс
    static let progressStart = Color(hex: "FF8D4D")
    static let progressEnd = Color(hex: "FFD36B")
    static let progressInactive = Color.white.opacity(0.1)
    
    // Специальные
    static let neonBlue = Color(hex: "5555FF")
    static let neonPink = Color(hex: "FE019A")
    static let premiumGold = Color(hex: "FFD700")
    
    // Разделители
    static let divider = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.1)
}
```

### Extension Color(hex:)
```swift
extension Color {
    init(hex: String) {
        // Парсинг hex-строки в RGB компоненты
        // Поддержка форматов: "RRGGBB" и "#RRGGBB"
    }
}
```

---

## Требование 2: Шрифты (AppFonts.swift)

Создать `enum AppFonts` + extension View для стилей:

```swift
enum AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let titleXL = Font.system(size: 32, weight: .bold)
    static let titleL = Font.system(size: 28, weight: .bold)
    static let titleM = Font.system(size: 24, weight: .semibold)
    static let subtitleL = Font.system(size: 18, weight: .medium)
    static let subtitleM = Font.system(size: 16, weight: .medium)
    static let bodyL = Font.system(size: 16, weight: .regular)
    static let bodyM = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let buttonPrimary = Font.system(size: 18, weight: .medium)
    static let buttonSecondary = Font.system(size: 16, weight: .medium)
}

extension View {
    func titleXLStyle() -> some View {
        self.font(AppFonts.titleXL).foregroundColor(AppColors.textPrimary)
    }
    func titleLStyle() -> some View { ... }
    func bodyLStyle() -> some View { ... }
    // ... все стили
}
```

---

## Требование 3: Отступы и размеры (AppSpacing.swift)

```swift
enum AppSpacing {
    // Padding
    static let screenPadding: CGFloat = 20
    static let screenPaddingLarge: CGFloat = 24
    static let containerPadding: CGFloat = 16
    static let containerPaddingLarge: CGFloat = 20
    static let blockSpacing: CGFloat = 16
    static let iconTextSpacing: CGFloat = 12
    
    // Радиусы
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
    static let buttonRadiusLarge: CGFloat = 20
    static let modalRadius: CGFloat = 32
    static let progressRadius: CGFloat = 4
    
    // Высоты
    static let buttonHeight: CGFloat = 56
    static let buttonHeightSecondary: CGFloat = 48
    static let listRowHeight: CGFloat = 72
    static let listRowHeightLarge: CGFloat = 80
    static let progressBarHeight: CGFloat = 8
    
    // Иконки
    static let iconSmall: CGFloat = 24
    static let iconMedium: CGFloat = 32
    static let iconLarge: CGFloat = 36
    static let iconXLarge: CGFloat = 44
    static let iconPermission: CGFloat = 80
}

enum AppShadow {
    static let soft = (color: Color.black.opacity(0.3), radius: 8, y: 4)
    static let medium = (color: Color.black.opacity(0.4), radius: 12, y: 6)
}
```

---

## Требование 4: Градиенты (AppGradients.swift)

```swift
enum AppGradients {
    static let ctaGradient = LinearGradient(
        colors: [AppColors.accentBlue, AppColors.accentPurple],
        startPoint: .leading, endPoint: .trailing
    )
    
    static let progressGradient = LinearGradient(
        colors: [AppColors.progressStart, AppColors.progressEnd],
        startPoint: .leading, endPoint: .trailing
    )
    
    static let auroraGradient = LinearGradient(
        colors: [Color(hex: "2F3DAF"), Color(hex: "6B3BDB"), Color(hex: "8B5CFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [AppColors.backgroundSecondary, AppColors.backgroundPrimary],
        startPoint: .top, endPoint: .bottom
    )
    
    static let successGradient = LinearGradient(
        colors: [AppColors.statusSuccess, Color(hex: "2BA88E")],
        startPoint: .leading, endPoint: .trailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [AppColors.statusWarning, AppColors.progressStart],
        startPoint: .leading, endPoint: .trailing
    )
}
```

---

## Требование 5: UI-компоненты

### 5.1. Кнопки
Создать 4 типа кнопок с `ScaleButtonStyle`:

- **PrimaryButton** — градиентный фон (ctaGradient), белый текст, 56pt высота, 16pt радиус, поддержка isLoading (ProgressView вместо текста)
- **SecondaryButton** — прозрачный фон + обводка (accentBlue), 48pt высота
- **GhostButton** — без фона, только текст (textSecondary)
- **IconButton** — круг 44pt с иконкой

### 5.2. Карточки
- **PrimaryCard** — backgroundCard фон, cardRadius, softShadow, иконка + заголовок + подзаголовок + бейдж + шеврон
- **ListCard** — строка списка 72-80pt, иконка в кружке + заголовок + счётчик
- **StatsCard** — числовое значение + единица + иконка

### 5.3. Модальные окна
- **StandardModal** — modalRadius, backgroundModal, анимация появления (scale + opacity)
- **PermissionModal** — полноэкранный, иконка 80pt, описание, две кнопки
- **AlertModal** — компактный, сообщение + 1-2 кнопки

### 5.4. Прогресс-бары
- **StorageProgressBar** — горизонтальный, progressGradient, 8pt высота
- **CircularProgress** — круговой, процент в центре, градиент обводки
- **SegmentedProgress** — сегменты для онбординга (active = accentBlue, inactive = white 20%)

### 5.5. Фоны
- **AuroraBackground** — анимированные радиальные градиенты, движение по синусоиде
- **DarkGradientBackground** — статический тёмный градиент
- **ParticleBackground** — плавающие частицы с opacity анимацией

### 5.6. Состояния
- **EmptyStateView** — иконка SF Symbol + заголовок + описание + опциональная кнопка
- **LoadingStateView** — ProgressView или CircularProgress
- **SuccessStateView** — иконка checkmark + статистика
- **ErrorStateView** — иконка exclamation + сообщение + кнопка Retry

---

## Требование 6: View Extensions

```swift
extension View {
    func cardStyle() -> some View {
        self.background(AppColors.backgroundCard)
            .cornerRadius(AppSpacing.cardRadius)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
    
    func shimmer() -> some View { ... }           // Shimmer-эффект загрузки
    func fadeEdge(_ edge: Edge, length: CGFloat)   // Затухание краёв
    func hideKeyboard()                            // Скрыть клавиатуру
    func readSize(onChange:)                        // Чтение размера view
    func `if`<T: View>(_ condition: Bool, transform: ...) // Условный модификатор
}
```

---

## Требование 7: HapticManager

```swift
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    static func lightImpact()
    static func mediumImpact()
    static func heavyImpact()
    static func success()
    static func warning()
    static func error()
    static func selection()
}
```

---

## Критерии приёмки

- [ ] Все цвета определены и используются из AppColors (не хардкод)
- [ ] Все шрифты определены в AppFonts
- [ ] Все отступы из AppSpacing
- [ ] UI-компоненты работают в превью
- [ ] Кнопки имеют анимацию нажатия
- [ ] Shimmer-эффект работает для загрузки
- [ ] Haptic feedback вызывается при ключевых действиях
- [ ] Все компоненты поддерживают Dynamic Type (accessibility)
