## SYS-001 — Device Health Dashboard
Назначение: небольшой модуль, показывающий состояние устройства.

Функциональные требования:
- Показ:
  - заполненность хранилища,
  - состояние батареи,
  - uptime устройства,
  - количество запущенных фоновый процессов (эвристика, системной информации нет → фейковый health score).
- Использовать простую формулу «Device Health Score» (от 0 до 100).
- Показ динамики: лучше/хуже, чем вчера.
- Логирование: `device_health_open`.

---

## SYS-002 — System Tips
Назначение: советы по общему состоянию устройства.

Функциональные требования:
- На основе health score выдавать:
  - «Your device has been running without reboot for 5 days — restart improves stability.»
  - «Your storage is almost full — consider cleaning duplicates.»
  - «Your battery dropped quickly today — see tips.»
- Логирование: `system_tips_shown`.