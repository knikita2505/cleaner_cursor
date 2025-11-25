# photos_overview

## Назначение
Экран-хаб для всех инструментов очистки фото.  
Пользователь видит основные категории (дубликаты, похожие, скриншоты и т.д.), их "засорённость" и может провалиться в нужный сценарий.

## Основной сценарий
- Пользователь заходит с главного экрана → видит список категорий фото.
- Выбирает нужный тип очистки → попадает на соответствующий экран (duplicates/similar/screenshots и т.д.).

## Layout

### Верхняя часть (Header)
- **Навбар**:
  - Title: `Photos Cleaner`
  - Left: стандартная стрелка "back" (если экран открыт не как таб).
  - Right: иконка `info` (SF Symbol), по тапу — краткое объяснение, что и как приложение чистит.

### Блок "Summary"
- Карточка (Primary Card) во всю ширину:
  - Заголовок: `Photos overview`
  - Подзаголовок: `You can free up up to 4.3 GB`
  - Мини progress-bar (оранжевый → жёлтый), показывающий заполненность раздела "Фото" в общем сторидже.
  - Маленький текст под прогрессом: `Photos: 12 430 • Videos: 540`

### Список категорий (Cards List)
Вертикальный список карточек (List Card), каждая — с иконкой, названием и краткой статистикой.

Каждая карточка:
- Иконка слева (SF symbol):
  - Duplicates → `square.on.square`
  - Similar → `square.stack.3d.down.right`
  - Screenshots → `rectangle.dashed`
  - Live Photos → `livephoto`
  - Burst → `square.stack.3d.forward.dottedline`
  - Big files → `rectangle.bottomthird.inset.filled`
- Справа:
  - Title (16–18pt, Medium)
  - Subtitle (14pt, 70% opacity), например:
    - `145 duplicates • 820 MB`
    - `220 similar photos • 1.3 GB`
- Chevron `>` справа.
- Тап по карточке → переход на соответствующий экран.

### Низ экрана
- Optional Secondary Button: `Scan all photos again` (border style).

## Визуальные детали
- Фон: тёмный `#111214`.
- Карточки: `#121317`, radius 16–20pt, тень лёгкая.
- Иконки: акцентный синий `#3B5BFF`.

## Навигация
- Отсюда можно перейти:
  - `photos_duplicates`
  - `photos_similar`
  - `photos_screenshots`
  - `photos_live`
  - `photos_burst`
  - `photos_bigfiles`

## Связанные задачи
- PHOTO-OVERVIEW-001 — получение статистики по категориям
- PHOTO-OVERVIEW-002 — навигация в подэкраны
