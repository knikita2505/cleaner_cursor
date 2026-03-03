# Пошаговые промты для ИИ-агента

## Как использовать
Каждый промт ниже — самостоятельная задача. Вставляйте в ИИ-агент один промт за раз. Дождитесь завершения, проверьте компиляцию, затем переходите к следующему.

---

## Промт 1: Фундамент проекта

```
Создай iOS проект (SwiftUI, iOS 17+, Swift) со следующей структурой:

AppName/
├── Core/
│   ├── Extensions/
│   ├── Navigation/
│   ├── Services/
│   ├── Theme/
│   └── Utilities/
├── Features/ (создай пустые директории для каждого модуля)
├── UI/Components/
├── Assets.xcassets/
└── Info.plist

Добавь через SPM:
- ApphudSDK: https://github.com/apphud/ApphudSDK
- AppsFlyerFramework-Dynamic: https://github.com/AppsFlyerSDK/AppsFlyerFramework-Dynamic

Настрой Info.plist:
- NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription
- NSContactsUsageDescription, NSFaceIDUsageDescription
- NSUserNotificationsUsageDescription, NSUserTrackingUsageDescription
- NSAdvertisingAttributionReportEndpoint: https://appsflyer-skadnetwork.com/
- Portrait only, Light status bar

Создай точку входа (App struct) с инициализацией Apphud и AppsFlyer.
Установи .preferredColorScheme(.dark) на корневом view.
```

---

## Промт 2: Дизайн-система

```
Создай дизайн-систему для iOS cleaner-приложения (тёмная тема).

Файлы (в Core/Theme/):

1. AppColors.swift — enum AppColors со статическими Color:
   - Фоны: backgroundPrimary (#0D0F16), backgroundSecondary (#111214), backgroundCard (#121317), backgroundModal (#0F1116)
   - Акценты: accentBlue (#3B5BFF), accentPurple (#7A4DFB), accentLilac (#A88CFF), accentGlow (#7FB9FF)
   - Текст: textPrimary (white), textSecondary (#E6E8ED), textTertiary (#AEB4BE)
   - Статусы: statusSuccess (#41D3B3), statusWarning (#FFB84D), statusError (#FF4D4D)
   - Прогресс: progressStart (#FF8D4D), progressEnd (#FFD36B)
   - Также добавь Color(hex:) extension

2. AppFonts.swift — enum AppFonts (SF Pro system):
   largeTitle 34 bold, titleXL 32 bold, titleL 28 bold, titleM 24 semibold,
   subtitleL 18 medium, subtitleM 16 medium, bodyL 16 regular, bodyM 14 regular,
   caption 12 regular, buttonPrimary 18 medium, buttonSecondary 16 medium
   + View extension для стилей (.titleXLStyle(), .bodyLStyle() и т.д.)

3. AppSpacing.swift — enum AppSpacing:
   screenPadding 20, containerPadding 16, blockSpacing 16,
   cardRadius 20, buttonRadius 16, modalRadius 32,
   buttonHeight 56, buttonHeightSecondary 48, listRowHeight 72,
   iconSmall 24, iconMedium 32, iconLarge 36, iconXLarge 44

4. AppGradients.swift — enum AppGradients:
   ctaGradient (accentBlue → accentPurple), progressGradient (progressStart → progressEnd),
   auroraGradient (для онбординга), cardGradient, successGradient, warningGradient
```

---

## Промт 3: UI-компоненты

```
Создай переиспользуемые SwiftUI компоненты (в UI/Components/):

1. Buttons/PrimaryButton.swift:
   - PrimaryButton(title, isLoading, action) — градиентный фон (ctaGradient), белый текст, 56pt, 16pt radius, ProgressView при loading
   - SecondaryButton — обводка, 48pt
   - GhostButton — только текст
   - IconButton — круг 44pt с иконкой
   - ScaleButtonStyle — animation scaleEffect(0.95) при нажатии

2. Cards/PrimaryCard.swift:
   - PrimaryCard(icon, title, subtitle, badge, showChevron) — backgroundCard, cardRadius, shadow
   - ListCard(icon, iconColor, title, count, subtitle) — строка списка 72pt
   - StatsCard(icon, value, unit) — статистика

3. Modals/StandardModal.swift:
   - StandardModal(title, content, buttons) — 32pt radius, backgroundModal
   - PermissionModal(icon, title, description, primaryButton, secondaryButton)
   - AlertModal(title, message, buttons)
   - ModalOverlay — затемнённый оверлей

4. Progress/ProgressBars.swift:
   - StorageProgressBar(progress) — progressGradient, 8pt
   - CircularProgress(progress) — круговой с % в центре
   - SegmentedProgress(total, current) — для онбординга
   - DotProgress(total, current) — для пагинации

5. Backgrounds/GradientBackgrounds.swift:
   - AuroraBackground — анимированные радиальные градиенты
   - DarkGradientBackground — простой тёмный
   - ParticleBackground — плавающие частицы

6. Common/EmptyState.swift:
   - EmptyStateView(icon, title, description, buttonTitle, action)
   - LoadingStateView(title, progress)
   - SuccessStateView(icon, title, stats, buttonTitle, action)
   - ErrorStateView(icon, title, message, retryAction)

Все компоненты должны использовать AppColors, AppFonts, AppSpacing.
Добавь SwiftUI Preview для каждого компонента.
```

---

## Промт 4: Навигация и состояние

```
Создай систему навигации (в Core/Navigation/):

1. AppState.swift — @MainActor class AppState: ObservableObject, singleton:
   - hasCompletedOnboarding (UserDefaults)
   - hasCompletedPermissions (UserDefaults)
   - showSplash: Bool
   - selectedTab: AppTab
   - dashboardPath: NavigationPath
   - showPermissionModal, currentPermissionType
   - enum AppTab (hide, swipe, clean, contacts, analytics) с иконками SF Symbol
   - enum PermissionType (photos, contacts, notifications)
   - enum DashboardDestination (photosOverview, duplicates, similar, screenshots, ...)

2. Router.swift — @MainActor class Router: ObservableObject, singleton:
   - sheet: Sheet?, fullScreenCover: FullScreenCover?
   - push(), pop(), popToRoot(), present(), dismiss()
   - enum Sheet, enum FullScreenCover
   - NavigationDestinationModifier

3. MainTabView.swift (в Features/Main/):
   - TabView с 5 вкладками
   - setupTabBarAppearance() — тёмный фон, accentBlue выбранный
   - DragGesture для свайп-навигации (порог 50pt, HapticManager.selection)
```

---

## Промт 5: Splash + Onboarding + Permissions

```
Создай экраны первого запуска:

1. SplashView.swift (Features/Splash/Views/):
   - Анимированная шестерня (вращение через .rotationEffect)
   - Частицы (sparkles, dust) с рандомными позициями
   - Прогресс-бар с анимацией
   - Название приложения
   - Длительность ~2-3 секунды, callback onComplete

2. OnboardingView.swift (Features/Onboarding/Views/):
   - 4 страницы (TabView + PageTabViewStyle)
   - Каждая страница: заголовок + описание + иллюстрация (SF Symbol)
   - SegmentedProgress наверху
   - Кнопки Next / Continue
   - На последнем экране: запрос ATT (AppsFlyerService.requestATTPermission)

3. PermissionsRequestView (в cleaner_cursorApp.swift или отдельно):
   - Запрос Photos, Contacts, Notifications по очереди
   - PermissionModal для каждого типа
   - Обработка отказа (кнопка Open Settings)

4. RootView (в cleaner_cursorApp.swift):
   - Логика: Splash → Onboarding → Paywall → Permissions → MainTabView
   - Фоновая загрузка данных при переходе к MainTabView
```

---

## Промт 6: PhotoService и Dashboard

```
Создай сервис работы с фото и главный экран:

1. PhotoService.swift (Core/Services/) — @MainActor, ObservableObject, singleton:
   Модели: PhotoAsset, DuplicateGroup, SimilarGroup, BurstGroup, LivePhotoAsset
   
   Методы:
   - requestAuthorization() → Bool
   - updateQuickCounts() — быстрый подсчёт скриншотов/Live/видео
   - scanDuplicatesIfNeeded() — поиск дубликатов по размеру файла (с кэшированием)
   - scanSimilarIfNeeded() — поиск похожих по дате (с кэшированием)
   - fetchScreenshots() — PHAsset.mediaSubtype == .photoScreenshot
   - fetchLivePhotos() — PHAsset.mediaSubtype == .photoLive
   - fetchBurstPhotos() — PHAsset.representsBurst
   - deletePhotos(_ assets:) — через PHPhotoLibrary.performChanges
   - convertLivePhotoToStill() — удаление видео-компонента
   
   Алгоритм дубликатов: группировка по fileSize → проверка creationDate (±1 сек)
   Алгоритм похожих: группировка по creationDate (интервал <10 сек)

2. ScanResultsCache.swift — кэш в JSON (ApplicationSupport/PhotoCache/), TTL 1 час

3. VideoService.swift — fetchAll, fetchLarge(>100MB), fetchShort(<10s), compress, delete

4. DashboardView.swift + DashboardViewModel.swift:
   - Индикатор хранилища (CircularProgress)
   - Карточки категорий (ListCard) с навигацией
   - Кнопка Scan, shimmer при сканировании

5. Все экраны фото: DuplicatesView, SimilarPhotosView, ScreenshotsView, LivePhotosView, 
   BurstPhotosView, BigFilesView, HighlightsView, PhotosOverviewView, VideosView, ShortVideosView
   
   Каждый: сетка фото (LazyVGrid 3 колонки), выбор, удаление с проверкой лимита
```

---

## Промт 7: Contacts + Secret Space

```
Создай модули контактов и секретного хранилища:

1. ContactsService.swift (Core/Services/) — 1000+ строк:
   - findDuplicatesSync() — по нормализованному номеру
   - findSimilarNamesSync() — Levenshtein distance
   - findNoNameContactsSync() / findNoNumberContactsSync()
   - mergeContacts() — объединение с сохранением всех данных
   - createBackup() / restoreContact() — бэкапы (UserDefaults, макс 3)
   - normalizePhoneNumber() — поддержка US, RU, UK, DE, JP, BR, CN, IN

2. Экраны контактов: ContactsCleanerView, DuplicateContactsView, SimilarNamesView,
   NoNameContactsView, NoNumberContactsView, AllContactsView, BackupsListView, BackupDetailView

3. SecretSpaceService.swift:
   - PIN (Keychain), биометрия (LocalAuthentication)
   - addPhotosFromLibrary() → Documents/SecretSpace/
   - Исключение из iCloud backup
   - SecretContact CRUD (UserDefaults)
   - deleteAllSecretData() — panic button

4. Экраны: PasscodeView (4-digit PIN + биометрия), SecretSpaceHomeView,
   SecretAlbumView, SecretContactsView, ProtectionSettingsView
```

---

## Промт 8: Swipe + Device Health + History

```
Создай оставшиеся модули:

1. SwipeProgressService.swift — хранение прогресса по месяцам (UserDefaults)
   MonthProgress, SwipeDecision (.keep/.delete), PhotoMonthGroup

2. SwipeHubView.swift — список месяцев с прогрессом
3. SwipeSessionView.swift — Tinder-свайп:
   - DragGesture, порог 100pt
   - Зелёный/красный индикатор
   - Rotation + translation анимация
   - Undo, batch-удаление при завершении

4. DeviceHealthService.swift — Health Score (0-100) из 4 компонентов:
   Storage (30%), Battery (30%), Performance (20%), Temperature (20%)
5. BatteryService.swift — UIDevice.batteryLevel, NotificationCenter мониторинг
6. StorageService.swift — FileManager.attributesOfFileSystem

7. DeviceHealthView, BatteryInsightsView, SystemTipsView

8. CleaningHistoryService.swift — записи очисток (UserDefaults, 6 мес)
9. CleaningHistoryView — summary cards, weekly bar chart, pie chart, рекомендации
```

---

## Промт 9: Подписки и интеграции

```
Создай систему подписок и внешние интеграции:

1. SubscriptionManager.swift — @MainActor, singleton:
   - isPremium (Apphud.hasPremiumAccess)
   - dailyFreeLimit = 50
   - canCleanItems(count:) → CleaningPermission
   - recordCleanedItems(count:) — UserDefaults, сброс в полночь
   - showPaywall(for:) / dismissPaywall()
   - PremiumFeatureModifier (ViewModifier с blur + замок)
   - RemainingItemsView (виджет лимита)

2. PaywallView.swift — онбординг-paywall:
   - AuroraBackground, анимация прогресса хранилища
   - Weekly / Yearly планы, загрузка цен из Apphud
   - Purchase / Restore / Terms / Privacy

3. PremiumPaywallView.swift — in-app paywall (sheet)

4. AppsFlyerService.swift — configure(), ATT, start(), logEvent(), logPurchase(),
   AppsFlyerLibDelegate, передача атрибуции в Apphud

5. NotificationService.swift — планирование на 14 дней (2/день), 12 вариантов текстов
6. FeatureTipService.swift — подсказки при первом посещении каждой функции
```

---

## Промт 10: Финальная сборка и проверка

```
Проверь и исправь весь проект:

1. Проверь что cleaner_cursorApp.swift корректно инициализирует:
   - Apphud.start(apiKey:) — ПЕРВЫЙ
   - AppsFlyerService.shared.configure() — ПОСЛЕ Apphud
   - RootView: Splash → Onboarding → Paywall → Permissions → Main

2. Проверь что MainTabView содержит все 5 вкладок с правильными views

3. Проверь что ВСЕ навигационные пути работают:
   - Dashboard → каждая категория фото
   - Contacts → каждая категория контактов
   - Swipe Hub → Swipe Session

4. Проверь что SubscriptionManager интегрирован:
   - Проверка лимита при КАЖДОМ удалении
   - Запись в CleaningHistory при КАЖДОМ удалении
   - Paywall при превышении лимита

5. Проверь компиляцию: 0 ошибок, минимум warnings

6. Проверь Apple Guidelines:
   - Все privacy descriptions в Info.plist
   - Restore Purchases доступен в paywall
   - Нет force-unwrap
   - Обработка ошибок

Составь отчёт о найденных проблемах и исправь их.
```
