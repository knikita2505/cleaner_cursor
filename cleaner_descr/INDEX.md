# MagicSwipe — Документация проекта

## Назначение
Эта документация описывает iOS cleaner-приложение **MagicSwipe** и служит шаблоном для автоматизированной генерации аналогичных приложений с помощью ИИ.

---

## Содержание

### 1. Обзор приложения
- [`00-overview.md`](./00-overview.md) — Описание приложения, функции, преимущества, архитектура, зависимости

### 2. Описание функций (подробно)

| # | Файл | Функция |
|---|------|---------|
| 1 | [`features/01-clean-dashboard.md`](./features/01-clean-dashboard.md) | Clean Dashboard — главный экран, категории фото/видео |
| 2 | [`features/02-swipe-clean.md`](./features/02-swipe-clean.md) | Swipe Clean — Tinder-сортировка фото по месяцам |
| 3 | [`features/03-contacts-cleaner.md`](./features/03-contacts-cleaner.md) | Contacts Cleaner — дубликаты, merge, бэкапы |
| 4 | [`features/04-secret-space.md`](./features/04-secret-space.md) | Secret Space — защищённое хранилище с PIN/биометрией |
| 5 | [`features/05-device-health.md`](./features/05-device-health.md) | Device Health — мониторинг устройства |
| 6 | [`features/06-cleaning-history.md`](./features/06-cleaning-history.md) | Cleaning History — аналитика очисток |
| 7 | [`features/07-onboarding-paywall.md`](./features/07-onboarding-paywall.md) | Onboarding, Paywall, подписки |
| 8 | [`features/08-navigation-ui-system.md`](./features/08-navigation-ui-system.md) | Навигация, дизайн-система, UI-компоненты |

### 3. Требования на реализацию

| # | Файл | Блок |
|---|------|------|
| 1 | [`requirements/01-project-setup.md`](./requirements/01-project-setup.md) | Настройка проекта, зависимости, Info.plist |
| 2 | [`requirements/02-design-system.md`](./requirements/02-design-system.md) | Дизайн-система (цвета, шрифты, компоненты) |
| 3 | [`requirements/03-navigation-and-state.md`](./requirements/03-navigation-and-state.md) | Навигация, AppState, Router, TabView |
| 4 | [`requirements/04-photo-cleaning.md`](./requirements/04-photo-cleaning.md) | PhotoService, VideoService, кэширование |
| 5 | [`requirements/05-contacts-cleaning.md`](./requirements/05-contacts-cleaning.md) | ContactsService, Levenshtein, merge, backup |
| 6 | [`requirements/06-secret-space.md`](./requirements/06-secret-space.md) | SecretSpace, Keychain, биометрия |
| 7 | [`requirements/07-swipe-clean.md`](./requirements/07-swipe-clean.md) | Swipe Clean, DragGesture, прогресс |
| 8 | [`requirements/08-device-health-analytics.md`](./requirements/08-device-health-analytics.md) | Health Score, Battery, Storage, History |
| 9 | [`requirements/09-subscriptions-and-paywall.md`](./requirements/09-subscriptions-and-paywall.md) | Apphud, Freemium, PaywallView |
| 10 | [`requirements/10-integrations.md`](./requirements/10-integrations.md) | AppsFlyer, PhotoKit, Contacts, Keychain, ATT |
| 11 | [`requirements/11-testing-plan.md`](./requirements/11-testing-plan.md) | План тестирования для ИИ-агента |

### 4. Промты для ИИ

| # | Файл | Назначение |
|---|------|------------|
| 1 | [`prompts/01-master-prompt.md`](./prompts/01-master-prompt.md) | Мастер-промт для генерации всего приложения |
| 2 | [`prompts/02-step-by-step-prompts.md`](./prompts/02-step-by-step-prompts.md) | 10 пошаговых промтов (по этапам) |
| 3 | [`prompts/03-testing-prompt.md`](./prompts/03-testing-prompt.md) | Промт для тестирования и code review |
| 4 | [`prompts/04-customization-prompt.md`](./prompts/04-customization-prompt.md) | Промт для адаптации под новое приложение |

---

## Как использовать (конвейер)

### Шаг 1: Генерация нового приложения
1. Откройте [`prompts/01-master-prompt.md`](./prompts/01-master-prompt.md)
2. Скопируйте промт и вставьте в ИИ-агент (Cursor/Claude/ChatGPT)
3. ИИ создаст полное приложение по шаблону

### Шаг 2: Поэтапная разработка (альтернатива)
1. Используйте промты из [`prompts/02-step-by-step-prompts.md`](./prompts/02-step-by-step-prompts.md)
2. Выполняйте по одному промту за раз
3. Проверяйте компиляцию после каждого этапа

### Шаг 3: Тестирование
1. Используйте промт из [`prompts/03-testing-prompt.md`](./prompts/03-testing-prompt.md)
2. ИИ проведёт code review и исправит ошибки
3. Проверьте соответствие чек-листам из [`requirements/11-testing-plan.md`](./requirements/11-testing-plan.md)

### Шаг 4: Кастомизация (если нужно другое приложение)
1. Заполните шаблон из [`prompts/04-customization-prompt.md`](./prompts/04-customization-prompt.md)
2. ИИ адаптирует шаблон под новые требования

---

## Статистика проекта

| Метрика | Значение |
|---------|----------|
| Файлов документации | 20 |
| Swift файлов в проекте | ~75 |
| Сервисов | 17 |
| Feature модулей | 11 |
| UI компонентов | 7 |
| Экранов | ~40+ |
| Сторонних зависимостей | 2 (Apphud, AppsFlyer) |
| Системных фреймворков | 7 (PhotoKit, Contacts, LocalAuth, Security, UserNotifications, AVFoundation, ATT) |
