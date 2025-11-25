# videos_compression

## Назначение
Экран для компрессии больших видеофайлов.  
Цель — уменьшить размер файлов, сохранив приемлемое качество, чтобы освободить значительное количество памяти.

---

## Основной сценарий
1. Пользователь открывает раздел Video Compression.
2. Приложение отображает список больших видео.
3. Пользователь выбирает одно или несколько видео для сжатия.
4. Настраивает параметры качества.
5. Запускает компрессию.

---

## Layout

### Header
- Title: **Video Compression**
- Subtitle: `Reduce file size while keeping great quality.`

### Summary (Primary Card)
- Заголовок: `Large videos detected`
- Подзаголовок: `Top videos over 200 MB`
- Внизу — маленькая статистика:
  - `Total potential savings: 6.1 GB`

### Video List
Каждый элемент списка:

#### Video Row Card
- Thumbnail (16:9), radius 12pt
- Overlay label (bottom-left): duration `03:21`
- Text right block:
  - Title: `Video • Jan 12, 2024`
  - Subtitle: `Size: 860 MB`
  - Small label: `Recommended to compress`
- Checkbox справа — default OFF

Видео сортируются:
- по размеру (крупнейшие сверху)

### Compression Settings Panel
Отображается в нижней части экрана (если выбрано ≥1 видео).

#### Panel elements:
- Title: `Compression Settings`
- Slider (с крупным бегунком):
  - Left: `High quality`
  - Right: `Smaller size`
- Live Preview:
  - “Before: 860 MB”
  - “Estimated after: 190–240 MB”
- Toggle:
  - `Keep original video` ON/OFF (default OFF)

### Bottom Summary Bar
- Left: `Selected: 3 videos`
- Right: Primary Button → **Compress videos**

---

## Логика

### Обработка списка
VideoService определяет:
- размер
- длительность
- битрейт
- разрешение

Файлы > 200MB выводятся первыми.

### Алгоритм компрессии
Использование:
- AVAssetExportSession
- Рекомендованные пресеты:
  - MediumQuality
  - LowQuality
  - HighestCompatible

Параметры выбираются на основе значения слайдера.

### UI Feedback
Во время компрессии:
- Fullscreen modal:
  - Progress bar
  - Text: `Compressing video 2/3…`
- При завершении:
  - Summary modal:
    - `You saved 3.1 GB`
    - CTA: `Done`

### Edge Cases
- Если видео слишком короткое для компрессии (например < 1.5 MB):
  - Видео отображается disabled
  - Subtitle: `Too small to compress`

- Если пользователь отключил доступ к медиатеке:
  - Перевод на экран permissions_photos

---

## Навигация
- Back → Videos overview
- Тап по видео → fullscreen preview с кнопкой “Include/Exclude”

---

## Внешний вид
- Фон: тёмный (#111214)
- Карточки: слегка светлее (#121317)
- Segments и чекбоксы — акцентный синий/фиолетовый
- Slider — с длинной цветной полосой (gradient)
- Preview-labels — маленькие капсулы `#2F3DAF → #7A4DFB`

---

## Связанные задачи
- VIDEO-COMP-001 — анализ больших видео
- VIDEO-COMP-002 — реализация слайдера качества
- VIDEO-COMP-003 — реализация AVAssetExportSession
- VIDEO-COMP-004 — UI и прогресс бар
