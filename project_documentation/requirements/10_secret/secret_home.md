# [SCREEN] secret_space_home

## Назначение
Главный экран **Secret Space** — зашифрованного хранилища.
Находится в табе "More".

---

## UI

- Заголовок: `Secret Space`.
- Подзаголовок: `Hide your private photos, videos and contacts.`
- Кнопка `Start Free Trial`, если у пользователя нет триала или подписки (функционал только Premium).
- Разделы:
  - `Secret Album` → `secret_album`
  - `Secret Contacts` → `secret_contacts`
- Блок `Protection`:
  - `Set Passcode`
  - `Face ID` (toggle)
- Статус: `X items hidden`.

---

## Логика

- При первом входе:
  - просим создать PIN-код;
  - включаем FaceID (если доступно).
- Все скрытые данные физически хранятся в выделенной зашифрованной области (или хотя бы маскируются в приложении).

---

## Аналитика
- `secret_space_open`
- `secret_space_enable`
