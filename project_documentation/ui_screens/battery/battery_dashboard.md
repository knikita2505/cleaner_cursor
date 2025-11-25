# battery_dashboard

## Назначение
Экран показывает текущее состояние батареи, charging state, health score и быстрые рекомендации.  
Это «мини-диагностика» устройства и уникальная фича приложения, повышающая доверие и ощущение “ценности”.

---

## Основной сценарий
1. Пользователь открывает Battery Dashboard из Dashboard или Battery Animation.
2. Видит текущее состояние батареи (процент, статус, здоровье).
3. Получает быстрые советы.
4. Может перейти к Battery Tips.
5. Может открыть Animation Screen.

---

## Layout и UI

### Header
- Title: **Battery**
- Right: Иконка Refresh (`arrow.clockwise`) — обновляет данные.

---

### Battery Status Card (Primary Card)
Большой блок с текущим состоянием батареи.

Элементы:
- **Battery Icon**:
  - кастомная: outline + заполнение градиентом
  - цвет зависит от %:
    - <20%: красный
    - 20–80%: зеленый/желтый
    - >80%: голубой/фиолетовый (в стиле приложения)
- **Percentage**: `72%`
  - 34–40pt, Bold
- **State Text**:
  - `Charging`
  - `Discharging`
  - `Full`
- **Temperature Badge** (опционально):
  - `Normal`
  - `Warm`
  - `Hot` (если > 35° по системным метрикам, если доступно)

---

### Battery Health Block
Secondary Card с метраками здоровья батареи.

Элементы:
- Title: `Battery Health`
- Value: `89%` (Medium 22–26pt)
- Subtitle: `Peak performance capacity`
- Small note:  
  _Values are estimated based on device activity_ (если данных мало)

Внизу: progress bar health score (0–100).

---

### Daily Consumption Block
Mini Card:

- Title: `Today's Battery Usage`
- Value: `12% consumed`
- Subtitle: `Higher than average` или `Normal`

Отображается по эвристике.

---

### Quick Tips Block
Карточка со сводкой:
- `Avoid full charges`
- `Your brightness is high today`
- CTA: **View full tips** → battery_tips

---

### CTA Buttons
- **Show Charging Animation** (Primary button)
- **View Battery Tips** (Secondary button)

---

## Цвета и стиль
- Фон: #111214
- Primary Card: #16171C
- Иконки — gradient (cyan → purple)
- Текст — белый с 70–85% opacity
- Progress bars — фирменная палитра Aurora

---

## Логика
- Обновлять состояние каждую секунду, если экран открыт.
- Health Score считать эвристически:
  - яркость,
  - резкие просадки,
  - charging cycles (если доступно),
  - исторические данные.

---

## Edge Cases
- Если данные недоступны → показывать “Basic battery info only”.
- Если permission ограничены — fallback.

---

## Связанные задачи
- BATT-001 — Battery Status Service
- BATT-003 — Battery Tips
- BATT-002 — Battery Animation
