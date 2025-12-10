# [SCREEN] photos_screenshots

## Назначение
Экран для массового удаления скриншотов — быстрый способ освободить много места.

---

## Структура UI

### 1. Header
- Заголовок: `Screenshots`
- Кнопка Back.
- Справа: сегментed control:
  - `All`
  - `Last 30 days`

### 2. Summary Bar
- `Screenshots: <N>`
- `Total size: <X MB/GB>`

### 3. Grid
- Сетка 3 в ряд;
- Каждый элемент:
  - превью скриншота;
  - чекбокс (по умолчанию включен для всех);
  - лёгкий overlay по hover/selection.

### 4. Quick Filters (опциональный горизонтальный скролл сверху)
- `Social media`
- `Chats`
- `System`
Просто подсказки, могут быть реализованы позже.

### 5. Bottom Bar
- `Selected: <N> • <X MB>`
- Кнопка `Delete selected`.

---

## Логика

- По умолчанию выбраны все скриншоты → пользователь скорее снимает галочки с тех, что нужны.
- Если включён фильтр `Last 30 days` — показываем только недавно созданные.
- Удаление — как и в других модулях: с подтверждением.

---

## Аналитика
- `screenshots_open`
- `screenshots_range_change`
- `screenshots_delete_success`
