# settings

## Назначение
Экран настроек приложения.  
Доступ к управлению подпиской, языком, политикой конфиденциальности, уведомлениями и системными функциями.

---

## Layout

### Header
- Title: **Settings**
- Нет второстепенных кнопок

---

## Blocks

### 1. Subscription Block (Primary Card)
Элементы:
- Title: `Subscription`
- Subtitle:
  - Если подписан: `Premium — active`
  - Если нет: `Free plan`
- CTA внутри карточки: `Manage` → Paywall или Restore screen

---

### 2. General Settings (List Items)

#### Notifications
- Row:
  - Icon: `bell`
  - Text: `Notifications`
  - Right: native toggle
  
#### Language
- Row:
  - Icon: `globe`
  - Text: `Language`
  - Right: текущий язык (`EN`, `JA`, `PT`)
  - Tap → opens language picker

#### App Appearance (на будущее)
- Row:
  - Icon: `circle.lefthalf.filled`
  - Text: `Appearance`
  - Right: `Dark`
  - (MVP: disabled)

#### Haptics
- Row:
  - Icon: `waveform`
  - Text: `Haptic feedback`
  - Right: toggle

---

### 3. Support Section

#### Restore Purchases
- Row:
  - Icon: `arrow.clockwise.circle`
  - Text: `Restore purchases`

#### Contact Support
- Row:
  - Icon: `envelope`
  - Text: `Support`

#### Rate App
- Row:
  - Icon: `star.fill`
  - Text: `Rate in App Store`

---

### 4. Legal Section

- Privacy Policy → opens external link
- Terms of Use → external link

---

## Внешний вид
- Фон: `#111214`
- Primary Card: `#14161B`
- List rows:
  - Height: 56–64pt
  - Иконки: accent blue/purple
- Текст:
  - Заголовки 16–17pt Medium
  - Вторичный текст 14pt 60% opacity

---

## Логика
- Language picker → сохраняет локаль в UserDefaults.
- Restore purchases:
  - Показывает системное окно.
  - Snackbar: `Restored successfully` или `Nothing to restore`.
- Notifications toggle:
  - При первом включении → системный запрос на разрешение.

---

## Связанные задачи
- SETTINGS-001 — интерфейс
- SETTINGS-002 — локализация
- SETTINGS-003 — обработка restore purchases
- SETTINGS-004 — notifications toggle
