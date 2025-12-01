# [SCREEN] settings_root

## Назначение
Главный экран настроек приложения.

---

## UI

Секции:

- Device & Privacy
  - `Secret Folder`
  - `Device Health`
  - 'Cleaning History'
  - `Delete my data`
  - ссылки на Policies
- Account & Premium
  - `Manage subscription`
  - `Restore purchases`
- Advanced
  - `Developer keys` (скрыто)
  - `Version X.Y.Z`

Long-press или секретная фраза на версии → `feature_flags` (см. системный файл).

---

## Логика
- Обычный пользователь не видит ни одного упоминания feature flags / dev tools.

---

## Аналитика
- `settings_open`
