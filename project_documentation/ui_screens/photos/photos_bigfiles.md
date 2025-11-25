# photos_bigfiles

## Назначение
Экран для быстрых “больших побед”: удаление крупных файлов (фото и видео), чтобы быстро освободить много места.

## Основной сценарий
1. Пользователь заходит сюда из Photos overview или Storage overview.
2. Видит список медиа, отсортированный по размеру.
3. Выбирает элементы → удаляет → видит сколько места освобождено.

## Layout

### Header
- Title: `Big Files`
- Subtitle: `Sort by size to free the most space quickly.`

### Filter Row
- Segmented control:
  - `All`
  - `Photos`
  - `Videos`
- Dropdown (или простая кнопка): Sort by:
  - `Size (largest first)` (по умолчанию)
  - `Date`
  - `Type`

### Files List
Каждый элемент (Row Card):
- Thumbnail слева (photo/video icon overlay)
- Text:
  - Primary: название/дата (`Video • Mar 3, 2025`)
  - Secondary: `Size: 1.2 GB • Duration: 03:21` (для видео) / `Size: 45 MB` (для фото)
- Checkbox справа:
  - По умолчанию не выбран.
- Маленький label снизу: `Recommended for deletion` (если >100MB).

### Bottom Summary Bar
Фиксированная панель внизу:
- Left:
  - Text: `Selected: 4 • Free up: 3.4 GB`
- Right:
  - Primary Button: `Delete selected`

## Визуальные детали
- Мини-иконка play для видео поверх thumbnail.
- Цвет label `Recommended` — жёлтый `#FFB84D`.

## Логика
- Список формируется PhotoService/VideoService с указанием размера.
- Можно задать минимальный порог (например, >20MB).
- При удалении — confirmation modal:
  - Title: `Delete 4 files?`
  - Subtitle: `They will be removed from your device permanently.`
- После успешного удаления:
  - Обновление списка.
  - Snackbar: `You freed up 3.4 GB`.

## Edge cases
- Нет файлов > порога:
  - Empty State: `No large files found above 20 MB.`
  - CTA: `Change filter` (откроет простой контрол для изменения порога).

## Связанные задачи
- PHOTO-BIG-001 — сбор списка больших файлов
- PHOTO-BIG-002 — сортировки и фильтры
- PHOTO-BIG-003 — удаление с подтверждением
