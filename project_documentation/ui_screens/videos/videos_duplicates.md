# videos_duplicates

## Назначение
Экран служит для выявления и удаления дубликатов видеофайлов в медиатеке.  
Цель — быстро освободить значительный объём памяти, так как видео обычно занимают много места.

---

## Основной сценарий
1. Пользователь открывает раздел "Duplicate Videos" из Photos/Video Overview.
2. Приложение автоматически анализирует медиатеку и определяет группы дубликатов видео.
3. Пользователь просматривает предварительный список.
4. Пользователь удаляет лишние копии — автоматически или вручную.

---

## Layout

### Header
- Title: **Duplicate Videos**
- Subtitle: `We found groups of identical or nearly identical videos.`
- Доп. кнопка справа: иконка `info` → показывает модалку “How duplicates are detected”.

### Summary Card (Primary Card)
- Заголовок: `Potential savings: 3.4 GB`
- Подзаголовок: `62 duplicate videos found`
- Маленький label: `Auto-select enabled`
- CTA внутри карточки — нет (информативный блок)

### Duplicate Groups List
Каждая группа дубликатов представлена следующим образом:

#### Карточка группы (Group Card)
- Миниатюра: квадрат 72–88pt, первое видео из группы.
- Справа блок:
  - Primary text: `Video group • 4 items`
  - Secondary text: 
    - Duration: `00:15`
    - Size: `180 MB each`
  - Badge: `Recommended: keep 1`

#### Под карточкой — список миниатюр группы (collapsible)
- Thumbnail (формат 16:9), справа чекбокс:
  - По умолчанию отмечены 3/4 (все кроме одной).
- Дополнительная информация под элементом:
  - `Created: Mar 14, 2025`
  - `Size: 178 MB`

### Bottom Summary Bar
Фиксируется при скролле:
- Слева: `Selected: 58 files • Free up: 3.4 GB`
- Справа: Primary Button → **Delete Selected**

---

## Внешний вид
- Фон: тёмный (#111214)
- Карточки групп: slightly lighter (#121317)
- Thumbnail-video: чёрная рамка 1pt, radius 8–12 pt
- Checkbox: акцентный фиолетово-синий
- Badge: маленькая капсула gradient (blue → purple)

---

## Логика

### Получение групп
Сервис VideoService:
- анализирует:
  - длительность (±1–2% tolerance)
  - резолюцию
  - размер файла
  - контрольные хэши (Core ML optional)
- группирует видео со 100% совпадением

### Автовыбор
- Приложение оставляет одну копию в каждой группе.
- Остальные отмечаются как "to delete".
- Пользователь может изменить выбор вручную.

### Удаление
- После нажатия **Delete Selected**:
  - Показ модалки-подтверждения
  - Progress bar: `Deleting 12/58…`
  - Обновление списка после выполнения

### Edge Cases
- Если группа содержит только 1 видео → скрывать такую группу.
- Если нет дубликатов:
  - Empty state:
    - Иллюстрация
    - Text: “No duplicate videos found”
    - Button: `Back to Cleaner`

---

## Навигация
- ← назад: возвращает к общему Video/Photos overview
- Info → открывает модалку
- Delete Selected → Summary confirmation

---

## Связанные задачи
- VIDEO-DUP-001 — детекция групп дубликатов
- VIDEO-DUP-002 — UI-группы и expandable list
- VIDEO-DUP-003 — массовое удаление
- VIDEO-DUP-004 — автоселект
