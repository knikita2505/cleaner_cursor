# Локализация MagicSwipe

## Решения

- Языки: `en` (source), `ja`, `es`, `pt-BR`
- Переводы in-app делает команда разработки (каталог строк)
- Бренд `Magic Swipe` / `MagicSwipe` не переводится
- Имя под иконкой (`CFBundleDisplayName` = MagicSwipe) не локализуем
- Метаданные App Store (описание, keywords, скриншоты) — отдельная задача после in-app локализации

## Стек (Apple)

- String Catalog: `cleaner_cursor/Localizable.xcstrings`
- System permission strings: `cleaner_cursor/InfoPlist.xcstrings`
- SwiftUI: `LocalizedStringKey` / `Text("…")`
- Сервисы и ViewModels: `String(localized:)`
- Плюралы: variations в каталоге (`one` / `other`)
- Даты: `FormatStyle` / `Locale.autoupdatingCurrent`
- Цены и размеры: StoreKit locale и `ByteCountFormatter` (не дублировать в каталоге)

## Не переводить

Product / placement / Apphud / AppMetrica / AppsFlyer IDs, URL, UserDefaults keys, SF Symbols, analytics events, товарные знаки Apple (Face ID, Live Photos, iCloud).

## Проверка в Xcode

1. Scheme → Run → Options → App Language: Japanese / Spanish / Portuguese (Brazil)
2. UI приложения берёт строки из `Localizable.xcstrings`
3. Системные диалоги Photos / Contacts / Face ID / ATT / Notifications:
   - заголовок и кнопки рисует iOS на **языке телефона**, Scheme App Language на них не влияет;
   - наш текст (usage description) — из `InfoPlist.xcstrings`, тоже по языку телефона;
   - экран «Как открыть доступ к контактам» (Limited Access) — системный UI iOS, его нельзя локализовать приложением.
4. Чтобы увидеть японские permission-диалоги, язык iPhone должен быть Japanese (не только App Language в scheme).
5. Tab bar, onboarding, paywall, alerts удаления, Secret Space, Analytics
6. Смена языка: локальные пуши используют `localizedUserNotificationString` (перевод в момент показа). Уже поставленные пуши со старым английским текстом пересоздаются при следующем запуске (`notifications_schedule_version`).

## Следующий этап

Метаданные App Store (описание, keywords, скриншоты) — после проверки in-app.
