# secret_folder_album

## Назначение
Подэкран Secret Folder для отображения содержимого конкретной «папки» или типа файлов (например: Photos, Videos, Favorites).  
Используется, если структура Secret Folder расширится (MVP допускает 1 общий альбом, но UI должен уметь масштабироваться).

---

## Основной сценарий
1. Пользователь в Secret Folder нажимает "Albums" или фильтр.
2. Открывается список альбомов (например: All files, Photos only, Videos only).
3. Пользователь выбирает альбом → видит сетку файлов.
4. Может включить Select Mode для удаления или перемещения.

---

## Layout

### Header
- Title: **Photos** (или любое имя альбома)
- Left: Back
- Right: Select

### Filters Row (optional)
- Segmented control:
  - `All`
  - `Photos`
  - `Videos`
  - (В MVP можно скрыть, но UI должен быть готов к добавлению)

### Grid (основной контент)
- 3x grid
- Ячейка:
  - Square 1:1
  - radius 12pt
  - overlay:
    - Если видео → маленькая иконка `play.fill` в правом нижнем углу
    - Если выбрано → прозрачная голубая плашка + галочка

### Select Mode Header
Появляется вместо обычного:
- Left: `Cancel`
- Center: `5 selected`
- Right: `Delete` (красный текст)

### Bottom Action Bar (если есть выбранные)
- Primary Button: `Move to…`
- Secondary Button: `Export`
- Text (маленький): `Files remain encrypted during export`

---

## Внешний вид
- Тёмный фон (#111214)
- Grid 3x с spacing 4–6
- Бейдж “video” — фиолетовый, круглый, 12–14pt
- Выбор файла:
  - голубой semi-transparent overlay (opacity 35%)
  - галочка gradient-filled

---

## Логика
- Альбомы фактически не нужны в MVP — это UI, работающий поверх одной коллекции.
- В будущем можно:
  - создавать альбомы,
  - перемещать файлы,
  - добавлять лейблы.

---

## Edge Cases
- Альбом пуст:
  - Иллюстрация
  - Text: `No files in this album yet.`
  - CTA: `Add files`

---

## Связанные задачи
- SECRET-ALBUM-001 — базовая фильтрация
- SECRET-ALBUM-002 — select mode
- SECRET-ALBUM-003 — удаление/экспорт
