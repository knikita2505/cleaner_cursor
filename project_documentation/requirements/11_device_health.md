# [SCREEN] device_health_overview

## Назначение
Экран `Device Health` с общим индексом состояния устройства.
Находится в табе "More".

---

## UI

- Большой индикатор `Health Score` (0–100) + цвет (зелёный/жёлтый/красный).
- Под ним:
  - `Storage`
  - `Battery`
  - `Performance`
  - `Temperature` (если доступно)
Каждый пункт — строка с иконкой и статусовыми бейджами (`Good`, `Needs attention`).

Тап по `Battery` → `battery_insights`.  
Тап по `Storage` → `main_dashboard`.  
Кнопка `View tips` → `system_tips_list`.

---

## Логика

- Health Score вычисляется по:
  - уровню заполненности хранилища,
  - состоянию батареи,
  - аптайму,
  - частоте падений приложений (если есть),
  - температуре.
- Обновляется при каждом заходе + по таймеру.

---

## Аналитика
- `device_health_open`
