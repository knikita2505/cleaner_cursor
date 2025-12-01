# [SCREEN] main_dashboard

## Назначение
Главный экран приложения. Показывает:
- сколько памяти можно освободить;
- ключевые категории медиа (фото/видео) — в самом верху;
- CTA для запуска триала и перехода к очистке.

Фокус: фотографии и видео — главный контент, с которого пользователь должен начать.

---

## Структура экрана

### 1. Header
- Системный статусбар iOS.
- Справа вверху: кнопка **“Start Free Trial”**:
  - pill-button, зелёный градиент;
  - нажатие → `paywall_main`.

### 2. Блок Storage Summary
- Текст: `Space to clean`.
- Крупное число: `<X.Y> GB` — оценка потенциально очищаемого объёма.
- Круговой индикатор (ring):
  - внешний круг — общий объём;
  - закрашенная часть — текущая заполненность/«мусор»;
  - анимация при обновлении.

Под числом — строка со статистикой:
- `Clutter: <A> GB` - не считать память, занятую видео
- `Apps & data: <B> GB`
- `Total: <C> GB`

### 3. Фото- и видео-категории (основная сетка)
Сетка 2×N карточек, каждая — «вход» в отдельный модуль.

Приоритет и порядок:
1. Duplicate photos
2. Similar photos
3. Screenshots  
4. Live Photos
5. Videos  
6. Short videos  
7. Screen recordings  

Каждая карточка:
- фон — превью из одного или нескольких реальных элементов;
- градиентный overlay для читаемости текста;
- заголовок (белый, 16pt): `Screenshots` / `Similar photos` / …
- подзаголовок (14pt): `<N> MB` или `<N> GB`;
- лёгкая тень; анимация нажатия (scale 0.96).

Тапы:
- Duplicate photos → `photos_duplicate`
- Similar photos → `photos_similar`
- Screenshots → `photos_screenshots`
- Videos → `photos_videos`
- Short videos → `photos_short_videos`
- Screen recordings → `photos_screen_recordings`

### 5. Tab Bar
Стандартный нижний таббар:

- **Clean** (активен)
- Swipe
- Email
- Hide
- More

Активная вкладка подсвечена акцентным цветом.

---

## Логика и поведение

### Обновление данных
- При каждом появлении экрана:
  - поднимаем кэш последних расчётов;
  - запускаем фоновое обновление оценок по категориям, если с последнего обновления прошло > 5 минут;
  - числовые значения обновляются плавно (анимация прибавления чисел с небольшим шагом).

### Достижение лимитов
- Если пользователь достиг лимита бесплатной версии (см. `subscriptions_and_free_limits`):
  - при попытке начать очистку через любую категорию после лимита → показываем `paywall_main`.

### A/B-логика
- Кнопка `Start Free Trial` и порядок карточек могут отличаться по флагам `feature_flags`.

---

## Аналитика
- `dashboard_open`
- `dashboard_category_tap` (property: category)
- `dashboard_trial_cta_tap`
- `dashboard_invite_bonus_tap`
- `dashboard_storage_refresh`

---

## Основные переходы
- → `paywall_main`
- → `invite_bonus_screen`
- → `photos_screenshots`
- → `photos_similar`
- → `photos_videos`
- → `photos_live`
- → `photos_short_videos`
- → `photos_screen_recordings`
