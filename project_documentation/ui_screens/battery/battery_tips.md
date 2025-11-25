# battery_tips

## Назначение
Список персонализированных и статических советов по сохранению батареи.  
Фича, усиливающая полезность приложения.

---

## Основной сценарий
1. Пользователь открывает Battery Tips.
2. Видит список рекомендаций.
3. Нажимает на совет → раскрывается подробное описание.
4. Некоторые советы динамические (зависят от состояния устройства).

---

## Layout

### Header
- Title: **Battery Tips**

---

### Tip Cards (List of expandable cards)
Каждая карточка:
- иконка (SF Symbol: bolt, thermometer, sun.max, clock)
- Title: короткая фраза
- Subtitle: персонализированная подсказка
- Upon tap → раскрытие (accordion expand)

#### Примеры карточек:

**1. Avoid charging to 100%**
- Subtitle: `Charging fully daily reduces battery lifespan`
- Expanded:
  - Avoid leaving phone on charger overnight  
  - Keep daily charge cycles between 20–80%

---

**2. Brightness is too high**
(Показывается только если brightness >70%)
- Subtitle: `High brightness drains the battery quickly`
- Expanded:
  - Enable auto-brightness  
  - Reduce brightness from Control Center

---

**3. Background processes**
- Subtitle: `Apps consuming battery in the background`
- Expanded:
  - Turn off background app refresh  
  - Update heavy apps  
  - Restart device every few days

---

**4. High temperature detected**
- Subtitle: `Heat can permanently damage battery health`
- Expanded:
  - Avoid charging while gaming  
  - Remove case during charging  
  - Keep device out of direct sunlight  

---

### CTA at bottom
- **Check Battery Status** → battery_dashboard

---

## Стиль
- Cards style: same as Cleaner (dark mode, smooth shadows).
- Icons: gradient cyan→purple.
- Expanded area animates smoothly.

---

## Логика
- Часть советов показывается динамически:  
  - high brightness  
  - long charging  
  - fast drain  
  - high temperature  
- Остальные — статические.

---

## Связанные задачи
- BATT-003 Battery Tips
- BATT-001 Battery Status
