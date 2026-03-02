# Функция: Secret Space — Секретное хранилище

## Общее описание

Secret Space — защищённое хранилище для приватных фото, видео и контактов. Доступ защищён паролем (4-значный PIN) и биометрией (Face ID / Touch ID). Файлы хранятся в зашифрованном виде в файловой системе приложения, исключены из iCloud backup.

**Вкладка:** Hide (первая вкладка TabView)

**Файлы реализации:**
- `Features/SecretSpace/Views/SecretSpaceHomeView.swift` — главный экран
- `Features/SecretSpace/Views/PasscodeView.swift` — ввод/создание пароля
- `Features/SecretSpace/Views/SecretAlbumView.swift` — секретный альбом (медиа)
- `Features/SecretSpace/Views/SecretContactsView.swift` — секретные контакты
- `Features/SecretSpace/Views/ProtectionSettingsView.swift` — настройки защиты
- `Core/Services/SecretSpaceService.swift` — основной сервис
- `Core/Services/SecretFolderService.swift` — работа с файлами

---

## Блоки функции

### Блок 1: Аутентификация (PasscodeView)

**Первый запуск:**
1. Пользователь создаёт 4-значный PIN-код
2. Подтверждение PIN-кода (ввод дважды)
3. Предложение включить биометрию (Face ID / Touch ID)

**Последующие входы:**
1. Экран ввода PIN-кода или биометрии
2. При 3 неудачных попытках — таймаут

**Техническая реализация:**
```swift
enum PasscodeMode {
    case create      // создание нового пароля
    case confirm     // подтверждение при создании
    case enter       // ввод для доступа
}

enum BiometricType {
    case none
    case faceID
    case touchID
}
```

**Хранение пароля:**
- Keychain Services (kSecClassGenericPassword)
- Ключ: определяется в SecretSpaceService/SecretFolderService
- Пароль хэшируется перед сохранением

**Биометрия:**
- `LocalAuthentication` framework
- `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`
- Проверка доступности: `LAContext().canEvaluatePolicy()`
- Определение типа: `LAContext().biometryType` (.faceID / .touchID)

### Блок 2: Secret Album (Медиа)

**Функционал:**
- Импорт фото/видео из Photo Library
- Просмотр в защищённом хранилище
- Удаление из секретного альбома
- Опция "Delete original from Photo Library" при импорте

**Техническая реализация:**
```swift
struct SecretMediaItem: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let dateAdded: Date
    let mediaType: MediaType    // photo / video
    let fileSize: Int64
    var thumbnail: UIImage?
    
    enum MediaType {
        case photo, video
    }
}
```

**Процесс импорта:**
1. Пользователь выбирает фото/видео через `PHPickerViewController` или из `PHAsset`
2. Фото загружается в полном разрешении через `PHImageManager`
3. Конвертация в JPEG/PNG data
4. Сохранение в `Documents/SecretSpace/` с уникальным UUID-именем
5. Опционально: удаление оригинала из Photo Library

**Хранение файлов:**
- Директория: `Documents/SecretSpace/`
- Файлы исключены из iCloud backup (`URLResourceValues.isExcludedFromBackup = true`)
- Имена файлов: `UUID().uuidString.jpg` / `.mp4`
- Метаданные хранятся в UserDefaults

### Блок 3: Secret Contacts (Контакты)

**Функционал:**
- Добавление контактов вручную (имя, телефон, email, заметки)
- Редактирование секретных контактов
- Удаление секретных контактов
- Контакты НЕ синхронизируются с системной адресной книгой

**Техническая реализация:**
```swift
struct SecretContact: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var email: String
    var notes: String
    let dateAdded: Date
}
```

**Хранение:** UserDefaults (JSON-encoded массив `[SecretContact]`)

### Блок 4: Настройки защиты (ProtectionSettingsView)

**Настройки:**
- Изменение PIN-кода
- Включение/выключение биометрии
- "Panic Button" — удаление всех секретных данных
- Статус защиты (включена биометрия или нет)

**Panic Button:**
- `SecretSpaceService.deleteAllSecretData()` — удаление всех файлов из SecretSpace, очистка метаданных
- Подтверждение через AlertModal

---

## Безопасность

### Уровни защиты
1. **PIN-код** — обязательный, 4 цифры
2. **Биометрия** — опциональная, Face ID / Touch ID
3. **Файловая система** — отдельная директория, исключена из бэкапа
4. **Keychain** — хранение пароля в защищённом хранилище iOS

### Ограничения текущей реализации
- Файлы НЕ шифруются дополнительно (только защита iOS Data Protection)
- Метаданные контактов в UserDefaults (не в Keychain)
- Нет возможности экспорта/импорта секретных данных
- Нет удалённого стирания

---

## Ограничения (Freemium)

- Создание Secret Space — бесплатно
- Количество элементов — может быть ограничено подпиской (настраивается через `SubscriptionManager`)
