# device_health_tips

## Назначение
Экран отображает расширенные рекомендации по улучшению производительности устройства.  
Советы динамические — зависят от данных health анализа.

---

## Основной сценарий
1. Пользователь открывает экран из Device Health Overview.
2. Видит список советов, отсортированных по приоритету.
3. Нажимает на советы → раскрытие пояснения.
4. Применяет рекомендации:
   - переходит в battery tips,
   - переходит в storage,
   - просто читает советы.

---

## Layout и UI

### Header
- Title: **Health Tips**

---

### Tips List (Expandable Cards)
Каждый tip — карточка, состоящая из:
- Иконка (gradient circle)
- Title: чёткая рекомендация
- Subtitle: проблема / причина
- По тапу → расширенный текст

---

## Примеры карточек

### Tip 1: Restart your device
- Icon: `power`
- Subtitle: `Your device hasn't been restarted in 5 days`
- Expanded text:
  - iOS накопляет временные системные процессы.
  - Перезагрузка каждые 2–3 дня улучшает стабильность.
  - После перезагрузки health score временно повышается.

---

### Tip 2: Reduce storage usage
- Icon: `trash`
- Subtitle: `Your storage is 84% full`
- Expanded:
  - Удалите похожие и дубликатные фото.
  - Сожмите большие видео.
- CTA: **Open Storage Cleaner**

---

### Tip 3: Battery usage is high
- Icon: `bolt`
- Subtitle: `Fast battery drain detected`
- Expanded:
  - Яркость дисплея выше нормы.
  - Фоновые процессы активны.
- CTA: **Open Battery Tips**

---

### Tip 4: Overheating detected
- Icon: `thermometer.sun`
- Subtitle: `Device temperature increased recently`
- Expanded:
  - Перегрев снижает ресурс батареи.
  - Уберите телефон с солнца или снимите чехол.

---

### Tip 5: Long uptime reduces stability
- Icon: `clock.fill`
- Subtitle: `Long session without restart`
- Expanded:
  - Рекомендуемая перезагрузка каждые несколько дней.

---

## CTA внизу
- Primary: **Improve Device Health**
  - Показывает небольшой popup:
    - «1. Clean storage  
       2. Review battery tips  
       3. Restart your device»

---

## Цвета
- Фон: #111214
- Карточки: #15161B
- Иконки: cyan→purple gradient
- Основной текст: white 90%
- Вторичный текст: white 60%

---

## Логика
- Советы генерируются динамически:
  - high storage → storage tips,
  - battery fast drain → battery tips,
  - long uptime → restart suggestion.
- Tips упорядочены по важности.
- Логирование:
  - `device_tips_open`
  - `device_tip_expanded`
  - `device_tip_cta`

---

## Edge Cases
- Если нет проблем → показывать:
  - Title: `Your device is in great condition!`
  - Subtitle: `No recommendations at this time.`
  - CTA: **Back to Health Overview**

---

## Связанные задачи
- SYS-002 System Tips
- BATT-003 Battery Tips
- STORAGE-001 Storage Analysis
