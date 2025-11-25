# secret_folder_passcode

## Назначение
Экран для установки/ввода PIN-кода для Secret Folder.  
Используется при первом запуске и при отсутствии Face ID.

---

## Основной сценарий
Есть три состояния экрана:

1. **Создание пароля (Setup Mode)**
   - Пользователь впервые открывает Secret Folder.
   - Нужно задать PIN.

2. **Подтверждение пароля (Confirm Mode)**
   - Пользователь повторно вводит PIN.

3. **Разблокировка (Unlock Mode)**
   - Пользователь вводит существующий PIN.

---

## Layout

### Header (нефиксированный)
- Если Setup Mode:
  - Title: `Create Passcode`
- Если Confirm Mode:
  - Title: `Confirm Passcode`
- Если Unlock Mode:
  - Title: `Enter Passcode`

### Subtitle
- Setup Mode: `This code will protect your private files.`
- Confirm Mode: `Re-enter your passcode.`
- Unlock Mode: `Enter your code to access the folder.`

### PIN Input Indicators
- 4–6 кружочков (в зависимости от выбранной длины)
- Пустые кружочки → outline
- Заполненные → filled с gradient

### Numeric Keypad
- 0–9
- Кнопка удаления (иконка backspace)
- Большие квадратные кнопки:
  - size: 72–80pt
  - radius 16pt
  - фон: `#1A1C22`

### Face ID Switch
(активен только после установки PIN)
- Toggle: `Unlock with Face ID`
- Subtitle: `Use biometrics when available`

### Bottom Buttons
- В Unlock Mode:
  - Secondary: `Forgot passcode?` (открывает инструкцию по сбросу через подтверждение личности — MVP может открыть просто предупреждение)
- В Setup Mode:
  - Skip (опционально — можно отключить для надёжности)

---

## Внешний вид
- Фон: тёмный (`#0D0F16`)
- Keypad кнопки — матово-серые, radius 16
- Ввод PIN:
  - заполненный кружочек — CTA gradient
  - пустой — 30% opacity border

---

## Логика
### Setup Mode
- Сохраняем PIN в Keychain (Secure Enclave если доступен).
- После создания → сразу переход в Confirm Mode.

### Confirm Mode
- Если совпадает → success → переход к содержимому Secret Folder.
- Если нет → shake animation + текст `Codes don’t match`.

### Unlock Mode
- Если 5 ошибок подряд → временная блокировка 30 секунд.
- Если включён FaceID → показываем FaceID prompt при открытии.

---

## Edge Cases
- Face ID недоступен:
  - Показываем только keypad.

- Пользователь забыл пароль:
  - Показать предупреждение:
    - `For security reasons, you must reset Secret Folder to regain access.`
    - CTA: `Reset folder` (удаляет содержимое)

---

## Связанные задачи
- SECRET-PASS-001 — сохранение PIN в Keychain
- SECRET-PASS-002 — FaceID интеграция
- SECRET-PASS-003 — keypad UI
