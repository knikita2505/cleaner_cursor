# [SCREEN] permissions_flow

## Назначение
Централизованный flow запроса системных разрешений: Фото, Уведомления, Почта/Аккаунты (если требуется).

---

## Экраны (можно как шаги внутри одного View)

### Шаг 1 — Photos Access
- Иконка «Фото».
- Заголовок: `Allow access to your Photos`
- Подзаголовок: `We need this to find duplicates and large items to clean up storage.`
- Под текстом — small badge `Your photos stay on device. We do not upload them.`

Кнопки:
- Primary: `Continue` → системный диалог доступа к фото.

### Шаг 2 — Notifications (опционально)
- Заголовок: `Stay on top of your device health`
- Описание: `We'll send occasional reminders and tips. You can change this later.`
- Кнопки:
  - `Enable notifications`
  - `Not now` (продолжить без пушей)

---

## Логика

- Разрешения запрашиваются строго после объясняющего экрана (никаких «слепых» системных поп-апов).
- При отказе от фото доступ к функционалу чистки блокируется до тех пор, пока пользователь не даст доступ через Settings (подсказка внутри экрана модулей photo).
- Все решения логируются.

---

## Аналитика
- `perm_flow_start`
- `perm_photos_granted` / `perm_photos_denied`
- `perm_push_granted` / `perm_push_denied`
