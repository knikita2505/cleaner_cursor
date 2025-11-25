# photos_highlights

## Назначение
Экран, показывающий “лучшие” фотографии пользователя (по локальным эвристикам), создающий ощущение “умного” ассистента.

## Основной сценарий
1. Пользователь открывает Highlights из Photos overview.
2. Приложение показывает curated подборку фото (10–50 штук).
3. Пользователь может:
   - сохранить их как альбом,
   - удалить часть “ненужных”,
   - либо использовать это как “инспекцию”.

## Layout

### Header
- Title: `Highlights`
- Subtitle: `Your best photos, selected automatically.`

### Summary Block
Primary Card:
- Text: `We picked 24 photos you might want to keep.`
- Small hint: `You can clean the rest from other sections.`

### Highlights Grid
- 3x grid:
  - Ячейка: квадрат, radius 12–16pt.
  - Бейджик в углу: `⭐` или `Best`.
- При тапе по фото → fullscreen viewer.

### Fullscreen Viewer
- Сворачиваемый хедер:
  - Назад
  - Title: `1 of 24`
- Снизу:
  - CTA: `Mark as favorite`
  - Secondary: `Remove from highlights`
- Можно свайпать между фото.

## Визуальные детали
- Бейджик `⭐` — маленький gradient label.
- Фон: стандартный тёмный.

## Логика
- Фото выбираются по эвристикам:
  - наличие лица,
  - чёткость,
  - яркость,
  - отсутствие очевидного дублирования.
- Логика эвристик реализуется в PhotoService, но для UI важно:
  - возможность обновить подборку (`Refresh` кнопка в верхнем правом углу).
- Кнопка `Create album`:
  - Secondary button внизу:
    - Text: `Save as album in Photos`
  - По нажатию создаётся альбом через PhotoKit с этими фото.

## Edge cases
- Если “хороших” фото мало:
  - `We couldn't find enough highlights yet. Try taking more photos!`

## Связанные задачи
- PHOTO-HIGHLIGHTS-001 — выбор кандидатов
- PHOTO-HIGHLIGHTS-002 — UI грид и fullscreen
- PHOTO-HIGHLIGHTS-003 — создание альбома
