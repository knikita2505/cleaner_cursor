# Мастер-промт: Генерация iOS Cleaner-приложения

## Как использовать этот файл
Вставьте этот промт в ИИ-агент (Cursor, ChatGPT, Claude) для создания полного iOS-приложения типа "Phone Cleaner". Промт ссылается на документы в этой директории — предоставьте их агенту по мере необходимости.

---

## ПРОМТ

```
Ты — senior iOS разработчик. Тебе нужно создать iOS-приложение для очистки и оптимизации iPhone.

## Общее описание
Приложение-клинер для iOS с функциями:
1. Очистка фото (дубликаты, похожие, скриншоты, Live Photos, burst, большие файлы)
2. Очистка видео (большие, короткие, сжатие)
3. Очистка контактов (дубликаты, похожие имена, без имени/номера, бэкапы)
4. Swipe Clean — Tinder-подобный интерфейс для быстрой сортировки фото по месяцам
5. Secret Space — защищённое хранилище с PIN и биометрией
6. Device Health — мониторинг батареи, хранилища, производительности, температуры
7. Cleaning History — аналитика очисток с графиками и рекомендациями
8. Freemium модель с подпиской (Apphud) и аналитикой (AppsFlyer)

## Технические требования
- iOS 17+, Swift, SwiftUI (ТОЛЬКО SwiftUI, без UIKit views)
- Архитектура: MVVM + Singleton Services
- Навигация: TabView (5 вкладок) + NavigationStack + Router
- Тёмная тема (ТОЛЬКО dark mode)
- Зависимости: ApphudSDK (подписки), AppsFlyerFramework-Dynamic (аналитика)

## Структура проекта
```
AppName/
├── Core/
│   ├── Extensions/      (Date+, String+, View+ extensions)
│   ├── Navigation/      (AppState, Router)
│   ├── Services/        (17 сервисов — Photo, Video, Contacts, SecretSpace, ...)
│   ├── Theme/           (AppColors, AppFonts, AppSpacing, AppGradients)
│   └── Utilities/       (HapticManager)
├── Features/
│   ├── CleaningHistory/ (Views/)
│   ├── Contacts/        (Views/)
│   ├── Dashboard/       (Views/, ViewModels/)
│   ├── DeviceHealth/    (Views/)
│   ├── Main/            (MainTabView)
│   ├── Onboarding/      (Views/)
│   ├── Paywall/         (Views/)
│   ├── Photos/          (Views/)
│   ├── SecretSpace/     (Views/)
│   ├── Splash/          (Views/)
│   ├── Swipe/           (Views/)
│   └── Videos/          (Views/)
├── UI/
│   └── Components/      (Backgrounds, Buttons, Cards, Common, Modals, Progress)
├── Assets.xcassets/
└── Info.plist
```

## Порядок разработки
Реализуй в следующем порядке:

### Этап 1: Фундамент
1. Создай проект Xcode с правильной структурой
2. Добавь SPM зависимости (Apphud, AppsFlyer)
3. Настрой Info.plist (все permissions)
4. Создай дизайн-систему (Theme: AppColors, AppFonts, AppSpacing, AppGradients)
5. Создай UI-компоненты (кнопки, карточки, модалки, прогресс-бары, фоны, состояния)
6. Создай Extensions (Date+, String+, View+)
7. Создай HapticManager

### Этап 2: Навигация
8. Создай AppState (глобальное состояние)
9. Создай Router (координатор навигации)
10. Создай MainTabView (5 вкладок со свайп-навигацией)
11. Создай SplashView (анимация загрузки)
12. Создай OnboardingView (4 экрана + ATT)

### Этап 3: Подписки
13. Создай SubscriptionManager
14. Создай PaywallView (онбординг-paywall)
15. Создай PremiumPaywallView (in-app paywall)

### Этап 4: Core Services
16. Создай StorageService
17. Создай PhotoService (дубликаты, похожие, скриншоты, Live, burst)
18. Создай ScanResultsCache
19. Создай VideoService
20. Создай ContactsService (дубликаты, похожие, merge, backup)

### Этап 5: Features
21. Создай DashboardView + DashboardViewModel
22. Создай все экраны Photos (Duplicates, Similar, Screenshots, LivePhotos, Burst, Big, Highlights)
23. Создай все экраны Contacts
24. Создай SwipeHubView + SwipeSessionView + SwipeProgressService
25. Создай SecretSpaceService + все экраны SecretSpace
26. Создай DeviceHealthService + BatteryService + экраны
27. Создай CleaningHistoryService + экран аналитики

### Этап 6: Интеграции
28. Создай AppsFlyerService
29. Создай NotificationService
30. Создай FeatureTipService
31. Подключи CleanerApp (точка входа, инициализация SDK)

## Дизайн-система
- Фон: #0D0F16 (основной), #111214 (секции), #121317 (карточки)
- Акценты: #3B5BFF (синий), #7A4DFB (фиолетовый)
- Текст: белый, #E6E8ED, #AEB4BE
- Прогресс: градиент #FF8D4D → #FFD36B
- CTA: градиент #3B5BFF → #7A4DFB
- Шрифт: SF Pro (system), размеры от 12pt до 34pt
- Радиусы: 16pt (кнопки), 20pt (карточки), 32pt (модалки)
- Высота кнопок: 56pt (primary), 48pt (secondary)

## Ключевые правила
1. Все данные через @Published + ObservableObject
2. Все UI через SwiftUI (нет UIKit views)
3. Все цвета из AppColors, шрифты из AppFonts, отступы из AppSpacing
4. async/await для асинхронных операций
5. @MainActor для классов с @Published
6. Нет force-unwrap (!)
7. Обработка ошибок через do/catch или guard
8. Haptic feedback на все ключевые действия
9. Кэширование результатов сканирования
10. Проверка лимита подписки перед каждым удалением

Начни с Этапа 1. Создай все файлы дизайн-системы и UI-компонентов.
```

---

## Примечания по использованию

1. Этот промт запускает полную разработку. Для поэтапной работы используйте промты из отдельных файлов.
2. Агенту может потребоваться несколько сессий для завершения всех этапов.
3. После каждого этапа проверяйте компиляцию проекта.
4. API-ключи для Apphud и AppsFlyer нужно заменить на реальные.
