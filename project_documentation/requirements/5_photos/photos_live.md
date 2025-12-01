# Экран: Live Photos Cleaner

## Назначение
Экран предназначен для анализа и очистки Live Photos — фото с коротким видеосегментом.  
Поскольку Live Photos занимают значительно больше места, чем обычные фотографии, приложение должно предлагать 3 действия:

1. **Оставить как Live Photo**  
2. **Сконвертировать в обычное фото** (Live → Still, сохраняется только ключевой кадр)  
3. **Удалить Live Photo**  

Цель — быстро освободить память, сохранив важные кадры для пользователя.

---

# Структура экрана

## 1. Header
- Заголовок: **Live Photos**
- Подзаголовок: `N items — X GB`
- Кнопка Back
- Кнопка дополнительных действий (⋯):
  - Select All
  - Deselect All
  - Sort (Newest / Oldest / Largest)
  - Convert All to Still Photos (если разрешено)

---

## 2. Информационная плашка
**“Live Photos take more space than regular photos. Convert them to still images to save storage.”**

- Плашка кликабельная: тап открывает мини-гайд о конвертации.

---

## 3. Список Live Photos

### Формат:
- Сетка 2×N
- Превью — ключевой кадр Live Photo
- Иконка "LIVE" в углу
- Размер файла (например: 4.8 MB)
- Дата создания

### Поведение карточки:
- Тап → открыть детальный просмотр Live Photo
- Лонг-тап → включить режим множественного выбора (checkbox)
- Swipe Left (опционально): быстрые действия → Delete / Convert

---

# 4. Детальный просмотр Live Photo (модалка)

### Элементы:
- Полноэкранное изображение
- Кнопка “Play Live Motion” (3 сек)
- Индикатор размера файла
- Дата / Location
- 3 кнопки действий:

### Кнопки действий:
#### 1. **Keep as Live**
- Оставляет файл без изменений
- Закрывает модалку

#### 2. **Convert to Still Photo**
- Конвертирует Live Photo в обычное фото:
  - извлекается ключевой кадр  
  - сохраняется как JPEG/HEIF  
  - Live-часть удаляется  
- Экономит 40–90% места  
- Показывает экономию:  
  **“Saved 3.4 MB”**
- После конвертации:
  - карточка исчезает из Live Photos  
  - появляется всплывающее уведомление

#### 3. **Delete**
- Запрашивает подтверждение  
- Удаляет Live Photo целиком

### Дополнительное поведение:
- Свайп вправо/влево для перемещения по списку
- При попытке конвертации сверх free-limit → Paywall

---

# 5. Режим множественного выбора

## Нижняя панель (Action Bar):
- Счётчик выбранных: “Selected: X”
- Кнопки:
  - **Convert Selected** (основная, синяя)
  - **Delete Selected** (красная)
  - **Keep All** (серая)

### Логика:
- Если пользователь выбрал элементы с разными статусами (некоторые уже есть как обычные):
  - кнопка Convert активна только для Live Photos
- При нажатии Convert:
  - показывается оценка экономии места  
    **“You will save ~XX MB by converting X items.”**
- При достижении free-limit:
  - любые действия вызывают Paywall

---

# 6. Автоматические предложения (AI-lite)

Перед рендером списка выполняется локальный анализ:
- размытые Live Photos → метка **“Low Quality”**
- случайные Live Photos (карман / движение)
- дубликаты по дате → **“Duplicate”**

### “Smart Convert” кнопка:
Показывается сверху, если найдено ≥5 низкокачественных Live Photos.

При нажатии:
- автоматически выбираются Live Photos с низким качеством
- пользователю предлагается:
  - Convert All  
  или
  - Delete All  

---

# 7. Free-limit логика

Если достигнут лимит бесплатной версии:
- кнопки Convert и Delete становятся прозрачными
- любые действия → Paywall
- появляется баннер:
  **“Free limit reached: up to 50 clean actions per day.”**

---

# 8. Edge Cases

### Нет Live Photos
- Иллюстрация
- Текст:  
  **“No Live Photos found”**  
  **“Try scanning again or choose another category.”**

### Live Photos только в iCloud
- карточка помечается как **“iCloud Only”**
- при попытке конвертации/удаления:
  → предупреждение:  
  “Download required to proceed.”

### Ошибка конвертации
- Показывается:  
  **“Could not convert this Live Photo. Try again.”**

---

# 9. Аналитика

### Screen events
- `live_photos_opened`
- `live_photo_preview_opened`
- `live_photo_motion_played`
- `live_photo_action_keep`
- `live_photo_action_convert`
- `live_photo_action_delete`
- `live_photo_bulk_convert`
- `live_photo_bulk_delete`
- `live_photo_smart_convert_tap`

### Errors
- `live_photo_convert_error`
- `live_photo_delete_error`
- `live_photo_load_failed`

---

# 10. Основные переходы
- Live Photos → Live Photo Preview
- Live Photos → Convert (success screen)
- Live Photos → Paywall
- Live Photos → Smart Convert
