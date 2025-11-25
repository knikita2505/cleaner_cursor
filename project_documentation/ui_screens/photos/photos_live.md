# photos_live

## Назначение
Экран для управления Live Photos:  
- конвертация Live Photos в обычные фото для экономии места  
- удаление лишних Live Photos.

## Основной сценарий
1. Пользователь выбирает категорию Live Photos в `photos_overview`.
2. Приложение сканирует медиатеку и выводит список Live Photos с оценкой потенциальной экономии.
3. Пользователь:
   - либо конвертирует Live Photo в статичное фото,
   - либо удаляет полностью.

## Layout

### Верхняя часть
- Навбар:
  - Title: `Live Photos`
  - Left: Back
- Под навбаром — небольшая подсказка:
  - Text: `Convert Live Photos to still images to save storage.`
  - 14pt, вторичный цвет, max 2 строки.

### Summary Card
Primary Card во всю ширину:
- Заголовок: `You can save up to 640 MB`
- Подзаголовок: `124 Live Photos found`
- Маленький бейджик: `Recommended to convert`

### Список Live Photos
Вертикальный список:
Каждый элемент:
- Превью (thumbnail) 60–72pt слева, с “Live” бейджем (маленький кружок с надписью `LIVE`).
- Справа:
  - Title: дата (`Mar 21, 2025`)
  - Subtitle: `2.8 MB • Live Photo`
  - Badge: `Save 2.1 MB by converting`
- Справа блок выбора:
  - Segmented control:
    - `Keep Live`
    - `Convert`
    - `Delete`
  (по умолчанию `Convert` выбран для всех элементов).

### Bottom Action Bar
Фиксированный блок внизу:
- Текст слева: `Selected: 124 • Save ~640 MB`
- Primary Button справа: `Apply changes`

## Визуальные детали
- Карточки списка — List Card.
- Бейдж `LIVE` — маленький капсула gradient (blue → purple).
- Выбор `Convert/Delete` — Segment control с плавной анимацией.

## Логика
- При загрузке:
  - ViewModel запрашивает Live Photos через PhotoService.
  - Автоматически проставляет “Convert” всем элементам.
- По нажатию `Apply changes`:
  - Для элементов `Convert` → создаётся статичное фото (тот же кадр), исходный Live удаляется.
  - Для `Delete` → Live Photo удаляется полностью.
- Показывать прогресс (inline) при массовой операции:
  - Простая полоска над кнопкой: `Processing 32/124…`.

## Edge cases
- Если Live Photos нет:
  - Показать Empty State:
    - Иллюстрация
    - Text: `No Live Photos to clean`
    - Secondary CTA: `Back to Photos cleaner`

## Связанные задачи
- PHOTO-LIVE-001 — поиск Live Photos
- PHOTO-LIVE-002 — логика “convert to still”
- PHOTO-LIVE-003 — массовая обработка и прогресс
