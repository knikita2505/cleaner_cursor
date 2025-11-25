# storage_overview

## Назначение
Экран служит для визуализации хранилища iPhone:
- показывает текущее использование,
- объясняет, что занимает место,
- позволяет быстро перейти к очистке крупных категорий,
- мотивирует пользователя купить подписку для глубоких функций.

---

## Основной сценарий
1. Пользователь открывает Storage Overview.
2. Видит диаграмму использования.
3. Просматривает категории, которые занимают место.
4. Переходит к детальным экранам фото, видео или других модулей.
5. Запускает “Deep Clean” (премиум).

---

## Layout

### Header
- Title: **Storage**
- Right: иконка обновления (`arrow.clockwise`) → повторный анализ

### Storage Card (Primary Card)
Большая карточка с горизонтальной бар-диаграммой.

Элементы:
- Title: `iPhone Storage`
- Subtitle: `84% used (112 GB of 128 GB)`
- Progress bar:
  - высота: 12pt
  - закругление: full
  - цвета:
    - Photos: yellow
    - Videos: purple
    - Apps: blue
    - System: gray
- Legend под баром: компактные цветные точки и подписи

### Category List
Список карточек категорий (List Card):

Каждая строка:
- Иконка:
  - Photos → `photo`
  - Videos → `film`
  - Contacts → `person.crop.circle`
  - Mail → `envelope.fill`
  - Other → `square.grid.2x2`
- Primary text: `Photos & Videos`
- Secondary text:
  - `12 970 items • 62.4 GB`
- Right side:
  - Mini CTA: `Clean` (small gradient pill)

Категории кликабельные → переход на соответствующие экраны.

### Deep Clean Banner
Secondary Card (но визуально выделенный):

- Gradient background (blue → purple)
- Title: `Deep Clean`
- Subtitle: `Smart scan for hidden junk & temporary files`
- CTA: **Try now** → Paywall

### Bottom
Secondary Button: `Rescan storage`

---

## Внешний вид
- Фон: `#111214`
- Primary Card: более светлый тёмно-серый (`#14161B`)
- Градиентная кнопка: CTA (blue→purple)
- Маленькие CTA внутри категорий — мини-капсулы.

---

## Логика
- StorageInfoService:
  - Получает данные от `FileManager`, `PhotoService`, `VideoService`.
- Rescan:
  - Заново вычисляет размеры категорий.
- Deep Clean:
  - Функция доступна только в Premium.
  - Если пользователь не подписан → переход на Paywall A.

---

## Edge Cases
- Если разрешения на фото не выданы:
  - Карточка Photos становится disabled.
  - Subtitle: "Permission required".
  - CTA: “Allow” → opens permissions screen.

---

## Связанные задачи
- STORAGE-001 — анализ памяти
- STORAGE-002 — UI диаграммы
- STORAGE-003 — навигация к модулям
- STORAGE-004 — Deep Clean
