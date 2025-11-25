# system_tips_list

## Назначение
Экран отображает список общесистемных рекомендаций по оптимизации устройства.  
Это «легкие» советы, не такие глубокие, как Device Health Tips, но напрямую связанные с повседневным использованием iPhone.  
Используются для удержания и демонстрации полезности приложения даже без запуска очистки.

---

## Основной сценарий
1. Пользователь открывает System Tips из Device Health или Settings.
2. Видит подборку советов: storage, battery, performance.
3. Читает краткие подсказки.
4. Нажимает на совет → раскрывается подробное описание.
5. По CTA может перейти в другие модули (Battery, Storage, Settings).

---

## Layout и UI

### Header
- Title: **System Tips**
- Right: иконка Refresh — обновить рекомендации.

---

### Tips Grouping
Список разделён на 3 группы:

1. **Storage Tips**  
2. **Battery Tips**  
3. **Performance Tips**

Каждая группа имеет заголовок (Section Header):

- STORAGE
- BATTERY
- PERFORMANCE

Стиль:  
- uppercase,  
- 13pt,  
- 50% opacity,  
- небольшой top inset.

---

### Tip Card (основной элемент)
Каждый совет — карточка:

- Background: #15161B, 12–14pt отступы  
- Left icon (gradient circle):
  - Storage → `externaldrive`
  - Battery → `bolt`
  - Performance → `speedometer`
- Title (primary): 15–16pt Medium  
- Subtitle (secondary): 13–14pt, 65% opacity  
- Chevron on right  
- Карточка кликабельна → раскрытие

---

### Expanded View (accordion)
При открытии:

- Разворачивается блок под карточкой:
  - более детальное объяснение  
  - шаги рекомендации  
  - иногда маленький CTA  
    (например «Open Battery Tips», «Open Storage Cleaner»)
- Анимация: smooth vertical expand (0.25s)

---

## Примеры советов

### STORAGE SECTION

**Tip 1 — Remove duplicate photos**
- Subtitle: `You may save storage space`
- Expanded:
  - iOS сохраняет много похожих фото.
  - Используйте Duplicate Cleaner для освобождения памяти.
  - CTA: **Open Photo Cleaner**

**Tip 2 — Compress large videos**
- Subtitle: `Videos occupy most of device storage`
- Expanded:
  - Видео >200MB можно сжать без существенной потери качества.
  - CTA: **Open Video Compression**

---

### BATTERY SECTION

**Tip 3 — Enable Low Power Mode**
- Subtitle: `Helps extend battery life`
- Expanded:
  - Режим снижает активность фоновых процессов.
  - Как включить:
    1. Settings → Battery  
    2. Enable Low Power Mode  
  - CTA: **Open Battery Tips**

**Tip 4 — Avoid charging overnight**
- Subtitle: `Overcharging affects battery health`
- Expanded:
  - Зарядка 0–100 ухудшает ресурс батареи.
  - Держите диапазон 20–80%.  

---

### PERFORMANCE SECTION

**Tip 5 — Restart your device occasionally**
- Subtitle: `Improves stability and performance`
- Expanded:
  - Перезапуск устраняет фоновые процессы.
  - Раз в 3–4 дня — оптимально.

**Tip 6 — Close unused heavy apps**
- Subtitle: `Background tasks may slow down device`
- Expanded:
  - Мессенджеры, навигация, камеры — сильные потребители ресурсов.

---

## CTA внизу экрана
- **Refresh Recommendations**  
  Обновляет список в соответствии с текущим состоянием устройства.

---

## Логика
- Рекомендации обновляются на основе:
  - storage usage,
  - battery level,
  - uptime,
  - статистики drain (эвристика),
  - количества последних удалений медиа.
- Частичная персонализация:
  - если storage >85% → показывать storage tips вверху.
  - если battery <30% → battery tips вверху.

---

## Edge Cases
- Если нет персональных рекомендаций:
  - Title: `Your device is in good shape!`
  - Subtitle: `No additional tips today`

---

## Связанные задачи
- SYS-002 System Tips
- BATT-003 Battery Tips
- STORAGE-001 Storage Analysis