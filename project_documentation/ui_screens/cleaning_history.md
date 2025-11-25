# cleaning_history

## Назначение
Экран отображает историю очисток пользователя: сколько фото/видео/контактов удалено, сколько места освобождено, динамику по дням и неделям.  
Этот экран — мощный retention-механизм: он визуально показывает пользу приложения, усиливает чувство ценности и подталкивает к повторным чисткам и подписке.

---

## Основной сценарий
1. Пользователь открывает Cleaning History из Dashboard или Settings.
2. Видит:
   - результаты за сегодня,
   - график за неделю,
   - суммарную экономию за месяц,
   - распределение по типам очистки.
3. Может перейти к Storage Overview или снова запустить чистку.
4. При отсутствии данных → показывается empty state с рекомендацией начать чистку.

---

## Layout и UI

### Header
- Title: **Cleaning History**
- Right: `calendar` icon → позволяет выбрать период (Today / Week / Month).

---

## Block 1 — Today’s Summary (Primary Card)

Содержит текущие результаты дня:

- **Title:** `Today`
- **Main metric (big text):**
  - `342 MB cleaned`
  - 34pt Bold
- **Submetrics:**
  - `Duplicates removed: 42`
  - `Similar photos cleaned: 21`
  - `Contacts merged: 3`
  - `Videos compressed: 1`
- Иконки слева: `photo.on.rectangle`, `square.stack.3d.down.right`, `person.crop.circle`, `film`

При отсутствии действий сегодня:
- показывать `0 MB cleaned`
- и кнопку: **Start cleaning**

---

## Block 2 — Weekly Trend Graph

Secondary Card с графиком чисток по дням недели.

### Элементы:
- Title: `Weekly Activity`
- 7 vertical bars:
  - Понедельник → Воскресенье
  - Высота бара = количество очищенных MB
- Цвет баров:
  - активные дни — gradient cyan→purple,
  - слабые дни — 40% opacity
- Подсветка лучшего дня:
  - Бар чуть выше и имеет glow.

### Подписи:
- Под графиком:
  - `Mon`, `Tue`, `Wed`…

---

## Block 3 — Monthly Summary (Primary Card)

Показывает суммарные данные за месяц:

- Title: `This Month`
- `Total cleaned: 8.4 GB` — крупный текст
- Breakdown (icon + text):
  - `Duplicates: 4.3 GB`
  - `Similar: 1.2 GB`
  - `Videos compressed: 2.1 GB`
  - `Contacts: minimal`

Дополнительно:
- «Premium users clean on average 4.2GB more»  
  (используется для усиления конверсии → Paywall)

---

## Block 4 — Cleaning Distribution (Pie Chart)

Небольшая круговая диаграмма:

Сегменты:
- Duplicate Photos  
- Similar Photos  
- Video Compression  
- Spam Emails  
- Contacts Cleanup  

Сегменты выделены цветами из брендбука.

По центру:  
`8.4 GB` — общий объем.

---

## Block 5 — Recommendations

Secondary Card:

- Title: `Recommendations`
- Dynamic messages:
  - `You haven’t cleaned in 3 days — storage may be wasted.`
  - `Large videos are consuming most space — compress them.`
  - `Your duplicate photos increased this week.`

При нажатии:
- переход на соответствующие cleaning-модули.

---

## CTA Section

### Primary CTA:
**Start Cleaning Now**
→ ведёт на photos_duplicates / storage_overview в зависимости от контекста.

### Secondary CTA:
**Open Storage Overview**

---

## Empty State (если нет истории)
Если пользователь не делал чисток:

- Иллюстрация (clean folder icon)
- Title: `No cleaning activity yet`
- Subtitle: `Start cleaning to track your progress`
- Button: **Start First Clean**

---

## Стиль
- Общий фон: #111214
- Primary cards: #14161B
- Secondary cards: #171A1F
- Графики — cyan→purple gradients
- Pie chart — фирменная палитра (yellow, purple, cyan, blue)

---

## Логика

### 1. Получение данных
- История хранится локально (кеш), обновляется после каждого действия.
- Данные агрегируются по дням/неделям/месяцам.

### 2. Динамические рекомендации
- Storage >85% → резкая рекомендация: “Free up space”
- Недавняя чистка фото → предложение сжать видео
- Нет чисток >3 дней → reminder

### 3. Анимации
- Weekly bars animate on appear.
- Pie chart rotates in softly on load.
- Big number counters animate 0 → value.

### 4. Analytics
- `history_open`
- `history_range_changed`
- `history_recommendation_click`
- `history_start_clean_click`

---

## Edge Cases
- Если размер очищенного <1MB → округлять до 1MB.
- Если данных слишком много → показывать последние 30 дней.
- Если кеш повреждён → fallback к 0MB.

---

## Связанные задачи
- CACHE-001 — Last Scan Cache  
- CACHE-002 — Daily Savings Summary  
- PHOTO-DUP-003 — Bulk Delete  
- VIDEO-COMP-003 — Compression  
- CONTACTS-003 — Merge/Delete  
