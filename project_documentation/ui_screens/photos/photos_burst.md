# photos_burst

## Назначение
Экран для работы с Burst-сериями:  
- пользователь выбирает лучший кадр в серии  
- остальные удаляются.

## Основной сценарий
1. Пользователь заходит в раздел Burst.
2. Видит список серий (группы).
3. Открывает серию → выбирает 1–2 лучших кадра.
4. Остальные автоматически помечаются к удалению → подтверждение удаления.

## Layout

### Верхняя часть
- Title: `Burst Photos`
- Subtitle под ним: `Multiple photos captured in a burst. Keep the best, remove the rest.`

### Список серий (Burst Groups)
Список карточек:

Каждая карточка:
- Превью (стек из 3–4 миниатюр).
- Text:
  - `15 photos in this burst`
  - `Taken on Mar 14, 2025`
- Badge справа: `Recommended: keep 1`
- Chevron для перехода → экран выбора кадра серии.

### Экран просмотра серии (дочерний экран)
При тапе на серию — новый экран (можно в этом же файле описать как Sub-view):

#### Header
- Title: `Select the best shots`
- Subtitle: `We will safely delete the rest after confirmation.`

#### Gallery
- Горизонтальный карусель/скролл миниатюр.
- При выборе кадра:
  - Он получает рамку (highlight).
  - Над ним маленький label: `Keep`.

#### Bottom actions
- Text: `You selected 1 of 15`
- Primary Button: `Keep selected & delete others`

## Визуальные детали
- Акцент на чистом, понятном UI: минимум текста, максимум превью.
- Мини-рамка при выборе кадра — акцентный gradient (blue → purple).

## Логика
- По умолчанию приложение может предложить “рекомендуемый кадр” (на основе резкости, лица и т.п.), но это необязательно для MVP.
- После подтверждения:
  - Оставить выбранные кадры.
  - Удалить все остальные из серии.
- После операции:
  - Показываем snackbar: `Burst cleaned: 14 photos removed`.

## Edge cases
- Если нет серийных фото:
  - Empty State: `No burst photos found`.

## Связанные задачи
- PHOTO-BURST-001 — поиск burst-серий
- PHOTO-BURST-002 — UI выбора лучших кадров
- PHOTO-BURST-003 — логика удаления остальных
