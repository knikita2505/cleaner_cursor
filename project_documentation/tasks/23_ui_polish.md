## UI-001 — Haptic Feedback Integration
Требования:
- Лёгкий feedback при:
  - выборе элемента,
  - свайпе,
  - успешной очистке,
  - нажатии CTA.
- Тактильная анимация на paywall CTA.

---

## UI-002 — Skeleton Loading
Требования:
- Для всех тяжёлых экранов (photos, videos):
  - показать skeleton cards,
  - убрать при первой выдаче данных.

---

## UI-003 — Micro Animations
Требования:
- анимировать:
  - hover эффект карточек,
  - появление контента,
  - смену секций.
- Важная деталь: не тормозить FPS.

---

## UI-004 — Smooth transitions between modules
Требования:
- использование matchedGeometryEffect для перехода:
  - dashboard → list screens,
  - paywall → settings,
  - highlights → album export.