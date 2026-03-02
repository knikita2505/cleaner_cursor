# Функция: Contacts Cleaner — Очистка контактов

## Общее описание

Contacts Cleaner — модуль для поиска и очистки дубликатов контактов, контактов без имени или номера, похожих имён. Включает функцию резервного копирования и восстановления контактов.

**Вкладка:** Contacts (четвёртая вкладка TabView)

**Файлы реализации:**
- `Features/Contacts/Views/ContactsCleanerView.swift` — главный экран
- `Features/Contacts/Views/DuplicateContactsView.swift` — дубликаты
- `Features/Contacts/Views/SimilarNamesView.swift` — похожие имена
- `Features/Contacts/Views/NoNameContactsView.swift` — без имени
- `Features/Contacts/Views/NoNumberContactsView.swift` — без номера
- `Features/Contacts/Views/AllContactsView.swift` — все контакты
- `Features/Contacts/Views/BackupsListView.swift` — список резервных копий
- `Features/Contacts/Views/BackupDetailView.swift` — детали копии
- `Core/Services/ContactsService.swift` — сервис контактов (1095 строк)

---

## Блоки функции

### Блок 1: Главный экран (ContactsCleanerView)

**Что отображает:**
- Общее количество контактов
- Карточки категорий с количеством найденных проблем:
  - Duplicate Contacts (дубликаты)
  - Similar Names (похожие имена)
  - No Name (без имени)
  - No Number (без номера)
- Кнопка "All Contacts" — просмотр всех контактов
- Кнопка "Backups" — управление резервными копиями
- Статус сканирования

**Техническая реализация:**
- `ContactsService.shared.scanAllCategories()` — сканирование всех категорий
- Результаты хранятся в `@Published` свойствах сервиса
- Используется `CNContactStore` для доступа к контактам

### Блок 2: Duplicate Contacts (Дубликаты контактов)

**Алгоритм поиска:**
1. Загрузка всех контактов через `CNContactStore`
2. Нормализация телефонных номеров (`normalizePhoneNumber(_:)`)
3. Группировка по нормализованному номеру телефона
4. Группы с >1 контактом = дубликаты

**Нормализация номеров:**
- Удаление всех нецифровых символов (пробелы, скобки, дефисы)
- Обработка международных кодов: US (+1), Russia (+7), UK (+44), Germany (+49), Japan (+81), Brazil (+55), China (+86), India (+91)
- Удаление leading zeros для стандартизации

**Модель данных:**
```swift
struct ContactDuplicateGroup: Identifiable {
    let id: UUID
    let matchType: DuplicateMatchType
    var contacts: [CNContact]
    var selectedForDeletion: Set<String>  // contact identifiers
}

enum DuplicateMatchType {
    case exactPhone      // точное совпадение номера
    case exactEmail      // точное совпадение email
    case exactName       // точное совпадение имени
}
```

**Действия пользователя:**
- Выбор контактов для удаления (чекбоксы)
- "Select All Duplicates" — выбрать все дубликаты (кроме первого в группе)
- "Merge" — объединение контактов (слияние данных в один)
- "Delete Selected" — удаление выбранных

### Блок 3: Similar Names (Похожие имена)

**Алгоритм поиска:**
1. Загрузка всех контактов
2. Сравнение имён попарно через алгоритм Levenshtein distance
3. Порог схожести: расстояние Левенштейна ≤ 2 символа (для коротких имён) или ≤ 30% длины (для длинных)
4. Исключение контактов, уже найденных как дубликаты

**Модель данных:**
```swift
struct ContactSimilarGroup: Identifiable {
    let id: UUID
    var contacts: [CNContact]
    var selectedForDeletion: Set<String>
}
```

### Блок 4: No Name Contacts (Контакты без имени)

**Алгоритм:**
- Фильтрация контактов где `givenName.isEmpty && familyName.isEmpty && organizationName.isEmpty`
- Отображение по номеру телефона или email

### Блок 5: No Number Contacts (Контакты без номера)

**Алгоритм:**
- Фильтрация контактов где `phoneNumbers.isEmpty`
- Отображение по имени

### Блок 6: Резервное копирование (Backups)

**Функционал:**
- Автоматическое создание бэкапа перед массовым удалением
- Ручное создание бэкапа по кнопке
- Хранение до 3 последних бэкапов (FIFO)
- Восстановление отдельных контактов или всего бэкапа

**Техническая реализация:**
```swift
struct ContactBackup: Identifiable, Codable {
    let id: UUID
    let date: Date
    let contacts: [BackupContact]
    var contactCount: Int
}

struct BackupContact: Identifiable, Codable {
    let id: String
    let givenName: String
    let familyName: String
    let organizationName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let note: String
}
```

**Хранение:** UserDefaults (ключ: `"contact_backups"`, JSON-encoded)

**Восстановление:**
- `ContactsService.restoreContact(_:)` — восстановление одного контакта
- `ContactsService.restoreAllContacts(from:)` — восстановление всего бэкапа
- Создание нового `CNMutableContact` с данными из `BackupContact`

---

## Операции с контактами

### Удаление
```swift
func deleteContacts(_ contacts: [CNContact]) {
    let store = CNContactStore()
    let request = CNSaveRequest()
    for contact in contacts {
        let mutable = contact.mutableCopy() as! CNMutableContact
        request.delete(mutable)
    }
    try store.execute(request)
}
```

### Объединение (Merge)
```swift
func mergeContacts(_ contacts: [CNContact]) {
    // 1. Собрать все данные из всех контактов
    // 2. Создать новый контакт с объединёнными данными
    // 3. Удалить исходные контакты
    // 4. Сохранить новый контакт
}
```

---

## Ограничения (Freemium)

- Просмотр категорий и результатов сканирования — бесплатно
- Удаление/объединение — в рамках дневного лимита 50 элементов
- Резервное копирование — бесплатно
