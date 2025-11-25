# secret_folder_home

## Назначение
Главный экран Secret Folder — приватного раздела приложения, куда пользователь может скрывать фото и видео.  
Этот экран должен давать ощущение «закрытости», премиальности и безопасности.

---

## Основной сценарий
1. Пользователь открывает Secret Folder из главного меню.
2. Если это первый запуск:
   - Показать экран установки пароля (переход на secret_folder_passcode).
3. Если пароль уже установлен:
   - Запрос Face ID / Touch ID / PIN.
4. После успешной авторизации пользователь видит свой закрытый альбом.

---

## Layout

### 1. Экран блокировки (если не авторизован)
#### Header
- Title: **Secret Folder**
- Subtitle: `Unlock to view your private files.`

#### Center Content
- Большая иконка замка (SF Symbol: `lock.shield.fill`, акцентный gradient).
- Текст под иконкой:
  - `Protected with Face ID`
  - маленький Caption: `Only you can unlock this folder`

#### Buttons
- Primary Button: **Unlock**
- Secondary Button: **Enter passcode**

При тапе:
- Unlock → FaceID prompt
- Enter passcode → переход на PIN keypad (secret_folder_passcode)

---

### 2. Домашний экран хранилища (после разблокировки)

#### Header
- Title: **Secret Folder**
- Right button: `+` (добавить файлы)
  - открывает ImagePicker/VideoPicker

#### Summary Bar / Stats
Primary Card:
- Заголовок: `8 photos • 4 videos`
- Подпись: `Last updated: Mar 12, 2025`
- Маленький бейдж: `Encrypted locally`

#### Grid View
- Фотосетка 3x
- Ячейка:
  - aspect ratio: 1:1
  - radius: 12pt
  - лёгкая тень
  - иконка типа файла (если видео)
  - при долгом тапе — включает Select Mode

#### Select Mode UI
- Наверху появляется:
  - Left: `Cancel`
  - Center: `3 selected`
  - Right: **Delete** (красная кнопка)

Внизу:
- Primary Button: **Move to album** (если есть папки)
- Secondary Button: **Export** (если нужно)

---

## Внешний вид
- Фон: `#111214`
- Grid: spacing 4–6pt
- Иконка замка — gradient CTA
- Кнопки: градиентные (Primary), прозрачные (Secondary)

---

## Логика
- Все файлы из Secret Folder хранятся:
  - в локальном зашифрованном контейнере (через FileManager + Keychain key),
  - не доступны через обычную галерею.
- При добавлении файла:
  - копия помещается в Secret Folder,
  - оригинал можно удалить (модалка с выбором):
    - `Move and delete original`
    - `Move only`

---

## Edge Cases
- Если папка пустая:
  - Иллюстрация (папка с замком)
  - Text: `Your private folder is empty.`
  - CTA: `Add files`

---

## Связанные задачи
- SECRET-001 — авторизация (FaceID/PIN)
- SECRET-002 — хранение зашифрованных файлов
- SECRET-003 — интерфейс грид-папки
- SECRET-004 — добавление/удаление файлов
