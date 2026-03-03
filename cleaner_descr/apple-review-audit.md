# Аудит проекта MagicSwipe для Apple App Store Review

## Часть 1: Проблемы и рекомендации

---

### CRITICAL — Могут привести к отклонению

#### 1. Хардкод API-ключей в коде
**Файлы:** `cleaner_cursorApp.swift` (строка 12), `AppsFlyerService.swift` (строки 21-24)

```swift
// cleaner_cursorApp.swift:12
Apphud.start(apiKey: "app_nmqxh6EVfa5mV9s2P29r2CTX7CpJ9M")

// AppsFlyerService.swift:21-24
private let devKey = "w2UscaGb7uRH4EtJUmWBj9"
private let appID = "6757766790"
```

**Риск:** Не причина отклонения напрямую, но API-ключи попадут в бинарник. Если репозиторий публичный — утечка. Для App Store Review это НЕ блокер, но bad practice.

**Рекомендация:** Вынести в Configuration.plist или xcconfig-файл, который не коммитится в git. Для production это не критично, но для безопасности проекта важно.

---

#### 2. Анимация на Paywall может быть расценена как ввод в заблуждение (Guideline 3.1.2)
**Файл:** `PaywallView.swift` (строки 410-414, 733-801)

```swift
@Published var photosCount: Int = 823
@Published var icloudCount: Int = 470
```

Paywall показывает ФИКТИВНЫЕ числа "823 Photos" и "470 iCloud", которые не имеют отношения к реальным данным пользователя. Анимация "100% → 25%" создаёт впечатление, что приложение УЖЕ проанализировало и может очистить столько файлов.

**Риск: ВЫСОКИЙ.** Apple может расценить это как:
- **Guideline 3.1.2** — введение в заблуждение относительно функциональности
- **Guideline 2.3.1** — вводящее в заблуждение описание

**Рекомендация:**
- Использовать реальные данные с устройства пользователя (PhotoService.shared.screenshotCount и т.д.)
- Или показывать generic иллюстрацию без конкретных чисел
- Или явно указать "Example" / "Illustration" рядом с числами

---

#### 3. Отсутствие описания подписки на Paywall (Guideline 3.1.2)
**Файлы:** `PaywallView.swift`, `PremiumPaywallView.swift`

Apple **требует** чтобы на экране подписки были указаны:
1. Длительность подписки — **есть** (weekly/yearly)
2. Цена — **есть** (загружается из Apphud)
3. Информация о бесплатном пробном периоде — **частично** (отображается "3-DAY FREE TRIAL", но нет чёткого указания, что после trial автоматически спишется)
4. Текст об автоматическом продлении — **ОТСУТСТВУЕТ**
5. Информация о том, как отменить — **ОТСУТСТВУЕТ**

**Риск: ВЫСОКИЙ.** Отклонение по Guideline 3.1.2(a).

**Рекомендация:** Добавить под CTA-кнопкой текст:

```
"Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase."
```

Или минимально:
```
"Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store Settings."
```

---

#### 4. Контакты как Premium-only функция (Guideline 3.1.1)
**Файл:** `SubscriptionManager.swift` (строка 299)

```swift
case .contacts:
    return true  // requiresPremium
```

Apple может потребовать, чтобы базовый функционал приложения был доступен бесплатно. Если Contacts Cleaner полностью заблокирован без подписки, ревьюер может посчитать, что приложение не предоставляет достаточной ценности бесплатным пользователям.

**Рекомендация:** Убедиться, что бесплатные пользователи могут хотя бы ПРОСМАТРИВАТЬ результаты сканирования контактов (дубликаты, похожие). Ограничивать только ДЕЙСТВИЯ (удаление, merge) лимитом 50/день.

---

### HIGH — Серьёзные опасения

#### 5. Сброс лимита через 24 часа вместо начала нового дня
**Файл:** `SubscriptionManager.swift` (строки 269-271)

```swift
let hoursSinceLastClean = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
if hoursSinceLastClean >= 24 {
```

Лимит сбрасывается через 24 часа после последней очистки, а не в полночь. Это может быть не критично для ревью, но создаёт непоследовательный UX: пользователь не знает, когда лимит сбросится.

**Рекомендация:** Сбрасывать в начале нового календарного дня:
```swift
if !Calendar.current.isDateInToday(lastDate) {
    // reset
}
```

---

#### 6. Force-unwrap в ссылках
**Файлы:** `PaywallView.swift` (строки 385-390), `PremiumPaywallView.swift` (строки 385-390), `OnboardingView.swift` (строки 97, 105)

```swift
Link("Terms of use", destination: URL(string: PaywallConstants.termsURL)!)
Link("Privacy Policy", destination: URL(string: PaywallConstants.privacyURL)!)
```

**Риск:** Если URL невалидный — crash. Маловероятно с константами, но bad practice.

**Рекомендация:** Использовать guard let или if let:
```swift
if let url = URL(string: PaywallConstants.termsURL) {
    Link("Terms of use", destination: url)
}
```

---

#### 7. Terms и Privacy Policy должны быть ДОСТУПНЫ
**URL:** `https://magicswipe.app/terms.html`, `https://magicswipe.app/privacy.html`

**Риск: ВЫСОКИЙ для ревью.** Apple проверяет, что ссылки Terms и Privacy Policy **реально работают**. Если сайт недоступен или возвращает 404 — отклонение.

**Рекомендация:** Убедиться, что:
- Домен `magicswipe.app` зарегистрирован и работает
- Страницы `/terms.html` и `/privacy.html` содержат корректные документы
- Privacy Policy описывает все собираемые данные (фото, контакты, tracking)
- Terms описывают условия подписки

---

#### 8. `Apphud.hasActiveSubscription()` vs `Apphud.hasPremiumAccess()`
**Файл:** `SubscriptionManager.swift` (строка 77)

```swift
let hasActiveSubscription = Apphud.hasActiveSubscription()
```

`hasActiveSubscription()` проверяет ТОЛЬКО подписки, но НЕ non-renewing purchases и lifetime. Если в будущем добавите lifetime-доступ, он не будет распознан.

**Рекомендация:** Использовать `Apphud.hasPremiumAccess()` — покрывает и подписки, и non-renewing, и lifetime:
```swift
let hasActiveSubscription = Apphud.hasPremiumAccess()
```

---

#### 9. ATT запрос слишком рано
**Файл:** `OnboardingView.swift` (строки 70-72)

```swift
if newPage == totalPages - 1 && !hasRequestedATT {
    requestATTPermission()
}
```

ATT запрашивается автоматически при переходе на последнюю страницу онбординга. Apple рекомендует показать pre-permission screen (объяснение зачем нужен tracking) ПЕРЕД системным диалогом. Без объяснения пользователи чаще отказывают.

**Рекомендация:** Добавить на последнюю страницу онбординга объяснение перед запросом ATT (custom alert или отдельная страница):
- "Help us improve your experience"
- "We use tracking to show you relevant ads and improve the app"
- Кнопка "Continue" → системный ATT диалог

---

### MEDIUM — Стоит исправить

#### 10. Нет кнопки "Manage Subscription" в настройках
В приложении нет экрана настроек с кнопкой управления подпиской. Apple рекомендует (не требует) предоставить способ перейти к управлению подпиской из приложения.

**Рекомендация:** Добавить в Settings:
```swift
Button("Manage Subscription") {
    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
        UIApplication.shared.open(url)
    }
}
```

---

#### 11. `Apphud.paywallShown()` вызывается корректно
**Файл:** `PaywallView.swift` (строка 658)

```swift
Apphud.paywallShown(paywall)
```

Это хорошо — Apphud требует этот вызов для корректной аналитики paywall. Проверено.

---

#### 12. Debug логирование в production
**Файл:** `AppsFlyerService.swift` (строка 69)

```swift
#if DEBUG
AppsFlyerLib.shared().isDebug = true
#endif
```

Это корректно — `isDebug` включается только в DEBUG. Но многочисленные `print()` выведутся и в production. Не критично, но замусоривает консоль.

**Рекомендация:** Обернуть все print в `#if DEBUG` или использовать `os_log` / `Logger`.

---

#### 13. iOS 14 проверки излишни при минимуме iOS 17
**Файл:** `AppsFlyerService.swift` (строки 101, 134)

```swift
if #available(iOS 14, *) {  // Минимум iOS 17 — проверка бессмысленна
```

**Рекомендация:** Удалить `#available(iOS 14, *)` проверки — проект требует iOS 17+, все эти API всегда доступны.

---

### LOW — Мелкие улучшения

#### 14. `@retroactive` на расширении ATTrackingManager
**Файл:** `AppsFlyerService.swift` (строка 330)

```swift
extension ATTrackingManager.AuthorizationStatus: @retroactive CustomStringConvertible
```

Работает, но Swift 6 может потребовать другой подход. Не блокер.

---

## Часть 2: Контрольный список Apple Guidelines

| # | Guideline | Статус | Комментарий |
|---|-----------|--------|-------------|
| 2.1 | App Completeness | ✅ OK | Приложение полное, нет placeholder экранов |
| 2.3.1 | Accurate Descriptions | ⚠️ RISK | Анимация на paywall может вводить в заблуждение |
| 2.3.3 | Screenshots | N/A | Проверить при подаче |
| 3.1.1 | In-App Purchase | ✅ OK | Подписки через StoreKit/Apphud |
| 3.1.2 | Subscriptions | ❌ ISSUE | Нет текста об автопродлении и отмене |
| 3.1.2(a) | Free Trial | ⚠️ RISK | Нет объяснения, что после trial спишется оплата |
| 3.1.2(b) | Restore Purchases | ✅ OK | Кнопка "Restore" есть на обоих paywall |
| 4.0 | Design | ✅ OK | Консистентный UI |
| 5.1.1 | Privacy Descriptions | ✅ OK | Все NSUsageDescription в Info.plist |
| 5.1.2 | User Tracking (ATT) | ✅ OK | ATT запрашивается, NSUserTrackingUsageDescription есть |
| 5.1.1(v) | Apple Sign In | N/A | Не используется |
| 2.5.1 | Only public APIs | ✅ OK | Только стандартные фреймворки |
| 4.3 | Spam/Duplicate | ✅ OK | Уникальное приложение |

---

## Часть 3: Интеграция AppsFlyer — проверка

| # | Пункт | Статус | Детали |
|---|-------|--------|--------|
| 1 | Dev Key | ✅ | Установлен |
| 2 | Apple App ID | ✅ | `6757766790` |
| 3 | Delegate | ✅ | `AppsFlyerLibDelegate` реализован |
| 4 | `waitForATTUserAuthorization` | ✅ | 60 секунд таймаут |
| 5 | SDK Start | ✅ | На `didBecomeActiveNotification` |
| 6 | ATT запрос | ✅ | В онбординге |
| 7 | Conversion Data → Apphud | ✅ | `Apphud.setAttribution()` в `onConversionDataSuccess` |
| 8 | Device Identifiers → Apphud | ✅ | `Apphud.setDeviceIdentifiers(idfa:idfv:)` |
| 9 | Customer User ID | ✅ | Связан с `Apphud.userID()` |
| 10 | Порядок инициализации | ✅ | Apphud → AppsFlyer (корректно) |
| 11 | `NSAdvertisingAttributionReportEndpoint` | ✅ | В Info.plist |
| 12 | SKAdNetwork | ⚠️ | Нет SKAdNetworkItems в Info.plist |

**Замечание по SKAdNetwork:** Для полноценной работы AppsFlyer с SKAN нужно добавить `SKAdNetworkItems` в Info.plist. AppsFlyer предоставляет список network IDs. Без этого — SKAN-атрибуция не работает. Не блокирует ревью, но снижает качество атрибуции.

---

## Часть 4: Интеграция Apphud — проверка

| # | Пункт | Статус | Детали |
|---|-------|--------|--------|
| 1 | `Apphud.start()` | ✅ | В App init, первый |
| 2 | API Key | ✅ | Задан |
| 3 | Загрузка products | ✅ | `Apphud.fetchPlacements()` |
| 4 | `Apphud.paywallShown()` | ✅ | Вызывается при показе paywall |
| 5 | `Apphud.purchase()` | ✅ | Покупка через Apphud |
| 6 | `Apphud.restorePurchases()` | ✅ | Восстановление реализовано |
| 7 | Trial eligibility | ✅ | `checkEligibilityForIntroductoryOffer` |
| 8 | Статус подписки | ⚠️ | `hasActiveSubscription()` вместо `hasPremiumAccess()` |
| 9 | AttrData from AppsFlyer | ✅ | Передаётся через `setAttribution` |
| 10 | Device Identifiers | ✅ | IDFA/IDFV передаются |

---

## Часть 5: Сводка действий (TODO перед подачей)

### Обязательно исправить (блокеры ревью):
1. **Добавить текст об автопродлении подписки** на PaywallView и PremiumPaywallView
2. **Убедиться что Terms и Privacy URLs работают** (magicswipe.app)
3. **Исправить или убрать фиктивные числа на paywall** (823 Photos, 470 iCloud)

### Настоятельно рекомендуется:
4. Заменить `hasActiveSubscription()` на `hasPremiumAccess()`
5. Добавить pre-ATT экран с объяснением
6. Добавить "Manage Subscription" кнопку
7. Исправить сброс лимита (на календарный день вместо 24h)
8. Убрать force-unwrap на URL

### Желательно:
9. Добавить SKAdNetworkItems в Info.plist
10. Обернуть print в #if DEBUG
11. Убрать iOS 14 availability checks
