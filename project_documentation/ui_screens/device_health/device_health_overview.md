# device_health_overview

## Назначение
Экран агрегирует состояние устройства в одном месте: health score, uptime, storage status, battery status, системные рекомендации.  
Служит вторичной точкой вовлечения и аргументом для премиум-функций.

---

## Основной сценарий
1. Пользователь открывает Device Health Overview.
2. Видит общий показатель здоровья устройства (Health Score).
3. Просматривает ключевые метрики (storage, battery, uptime).
4. Получает быстрые советы и может перейти к расширенным рекомендациям.
5. Может перейти в Battery Dashboard или Storage Overview.

---

## Layout и UI

### Header
- Title: **Device Health**

---

### Health Score Block (Primary Card)
Большая карточка с визуализацией «здоровья» устройства.

Элементы:
- Title: `Health Score`
- Circular progress (similar style to battery animation ring)
  - показывает уровень 0–100
  - цвета:
    - 0–50: красный gradient
    - 50–80: жёлтый
    - 80–100: фирменный cyan→purple
- Large number inside круга: `82`
  - 34pt Bold
- Subtitle:  
  - `Good condition` / `Normal` / `Needs attention`

---

### Device Metrics Section
Список 3 больших мини-карточек:

#### 1. Storage
- Icon: `square.grid.2x2`
- Title: `Storage`
- Subtitle: `112 GB / 128 GB (84%)`
- Indicator: colored bar
- Tap → storage_overview

#### 2. Battery
- Icon: `battery.100`
- Title: `Battery`
- Subtitle: `72%, Charging`
- Tap → battery_dashboard

#### 3. Uptime
- Icon: `clock.fill`
- Title: `Uptime`
- Subtitle: `56 hours since last restart`
- (эвристика: если uptime >96h → подсказка)

---

### “Issues Detected” Block (optional)
Secondary Card, отображается только если есть проблемы.

Элементы:
- Title: `We found 2 potential issues`
- List:
  - `High storage usage`
  - `Device hasn’t been restarted for a long time`
- CTA (small): **View tips** → device_health_tips

---

### Quick Actions Section
Горизонтальный список кнопок (pill-buttons):

- **Clean Storage**
  - Icon: `trash`
  - Tap → photos_duplicates or storage_overview

- **Battery Tips**
  - Icon: `bolt`
  - Tap → battery_tips

- **Restart Suggestion**
  - Icon: `power`
  - Tap → system_tip (modal with explanation)

---

## Стиль
- Фирменный Aurora gradient оттенки для карточек.
- Primary Card: чуть светлее фона (#14161B).
- Secondary Card: #171A1F.
- Large circle animates at opening (1.1 → 1.0 scale).

---

## Логика
- Health Score расчёт:
  - Storage weight (40%)
  - Battery condition weight (40%)
  - Uptime weight (20%)
- Если uptime > 5 дней → health score падает.
- Если storage > 85% → health score падает.
- Если батарея low health → большой штраф.

---

## Edge Cases
- Если данных мало → показывать `Limited data available`.
- При ошибке получения метрик → fallback с нейтральными значениями.

---

## Связанные задачи
- SYS-001 Device Health Dashboard
- STORAGE-001 Storage Analysis
- BATT-001 Battery Status Service
- SYS-002 System Tips
