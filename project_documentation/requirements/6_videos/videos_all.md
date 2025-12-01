# [SCREEN] videos_all

## Назначение
Экран для работы с **крупными видеофайлами**: просмотр, удаление, отправка в компрессию.

---

## Структура UI

### 1. Header
- Заголовок: `Videos`
- Back.
- Справа: toggle-кнопка `Sort by size / Sort by date`.

### 2. Summary Bar
- `Videos: <N>`
- `Total size: <X GB>`
- Highlight: `Top 10 largest videos: <Y GB>`

### 3. List (vertical)
Каждый элемент списка:
- превью кадра;
- длительность (`mm:ss`);
- размер (`X MB/GB`);
- дата;
- бейдж `Huge`, если > 500MB;
- справа: три точки (`...`) с меню:
  - `Delete`
  - `Compress`
  - `Open in Photos`

### 4. Bottom Bar
- Мультивыбор (чекбоксы слева у элементов);
- `Selected: <N> • <X GB>`
- Кнопки:
  - `Delete`
  - `Compress`

---

## Логика

### Сканирование
- При первом входе делается глубокое сканирование библиотеки видео с подсчётом размера.

### Compress
- Жмём `Compress`:
  - открывается мини-sheet с выбором:
    - High quality (30–40% экономии)
    - Medium (60%)
  - По завершении:
    - оригинал можно удалять (по настройкам).
    - создаём лог в истории.

### Free-limit
- Компрессия может быть частично доступна в free (1 видео в день), остальное — через paywall.

---

## Аналитика
- `videos_open`
- `videos_sort_change`
- `video_compress_start` / `video_compress_success`
- `video_delete_success`
