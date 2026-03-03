# Требования: Очистка контактов

## Цель
Реализовать ContactsService для поиска дубликатов, похожих имён, пустых контактов. Резервное копирование и объединение контактов.

---

## Требование 1: ContactsService

### Класс
```swift
class ContactsService: ObservableObject {
    static let shared = ContactsService()
    
    private let store = CNContactStore()
    
    @Published var isScanning = false
    @Published var totalContacts: Int = 0
    @Published var duplicateGroups: [ContactDuplicateGroup] = []
    @Published var similarGroups: [ContactSimilarGroup] = []
    @Published var noNameContacts: [CNContact] = []
    @Published var noNumberContacts: [CNContact] = []
    @Published var backups: [ContactBackup] = []
}
```

---

## Требование 2: Поиск дубликатов контактов

### Алгоритм

```swift
func findDuplicatesSync(in contacts: [CNContact]) -> [ContactDuplicateGroup] {
    var phoneMap: [String: [CNContact]] = [:]
    
    for contact in contacts {
        for phone in contact.phoneNumbers {
            let normalized = normalizePhoneNumber(phone.value.stringValue)
            if !normalized.isEmpty {
                phoneMap[normalized, default: []].append(contact)
            }
        }
    }
    
    return phoneMap
        .filter { $0.value.count > 1 }
        .map { ContactDuplicateGroup(
            id: UUID(),
            matchType: .exactPhone,
            contacts: $0.value,
            selectedForDeletion: Set()
        )}
}
```

### Нормализация номеров телефонов

```swift
func normalizePhoneNumber(_ number: String) -> String {
    // 1. Удалить все нецифровые символы
    var digits = number.filter { $0.isNumber }
    
    // 2. Обработка международных кодов
    if digits.hasPrefix("1") && digits.count == 11 { digits.removeFirst() }   // US
    if digits.hasPrefix("7") && digits.count == 11 { digits.removeFirst() }   // Russia
    if digits.hasPrefix("44") && digits.count == 12 { digits.removeFirst(2) } // UK
    if digits.hasPrefix("49") && digits.count == 12 { digits.removeFirst(2) } // Germany
    if digits.hasPrefix("81") && digits.count == 12 { digits.removeFirst(2) } // Japan
    if digits.hasPrefix("55") && digits.count == 12 { digits.removeFirst(2) } // Brazil
    if digits.hasPrefix("86") && digits.count == 13 { digits.removeFirst(2) } // China
    if digits.hasPrefix("91") && digits.count == 12 { digits.removeFirst(2) } // India
    
    // 3. Удалить ведущие нули
    while digits.hasPrefix("0") && digits.count > 1 { digits.removeFirst() }
    
    return digits
}
```

---

## Требование 3: Поиск похожих имён

### Алгоритм (Levenshtein distance)

```swift
func findSimilarNamesSync(in contacts: [CNContact], excludeIds: Set<String>) -> [ContactSimilarGroup] {
    var groups: [ContactSimilarGroup] = []
    var processed: Set<String> = Set()
    
    for i in 0..<contacts.count {
        if processed.contains(contacts[i].identifier) { continue }
        if excludeIds.contains(contacts[i].identifier) { continue }
        
        var similar: [CNContact] = [contacts[i]]
        let name1 = fullName(contacts[i]).lowercased()
        
        for j in (i+1)..<contacts.count {
            if processed.contains(contacts[j].identifier) { continue }
            let name2 = fullName(contacts[j]).lowercased()
            
            if levenshteinDistance(name1, name2) <= threshold(for: name1) {
                similar.append(contacts[j])
                processed.insert(contacts[j].identifier)
            }
        }
        
        if similar.count > 1 {
            processed.insert(contacts[i].identifier)
            groups.append(ContactSimilarGroup(id: UUID(), contacts: similar, selectedForDeletion: Set()))
        }
    }
    
    return groups
}

func threshold(for name: String) -> Int {
    if name.count <= 4 { return 1 }
    if name.count <= 8 { return 2 }
    return max(2, name.count * 3 / 10) // 30% длины
}
```

---

## Требование 4: Контакты без имени / без номера

```swift
func findNoNameContactsSync(in contacts: [CNContact]) -> [CNContact] {
    contacts.filter {
        $0.givenName.trimmingCharacters(in: .whitespaces).isEmpty &&
        $0.familyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        $0.organizationName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

func findNoNumberContactsSync(in contacts: [CNContact]) -> [CNContact] {
    contacts.filter { $0.phoneNumbers.isEmpty }
}
```

---

## Требование 5: Объединение контактов (Merge)

### Алгоритм
```swift
func mergeContacts(_ contacts: [CNContact]) throws {
    guard contacts.count >= 2 else { return }
    
    let merged = CNMutableContact()
    
    // 1. Собрать все уникальные данные
    var allPhones: [CNLabeledValue<CNPhoneNumber>] = []
    var allEmails: [CNLabeledValue<NSString>] = []
    var bestName = (given: "", family: "")
    
    for contact in contacts {
        // Выбрать лучшее имя (самое полное)
        if contact.givenName.count + contact.familyName.count > 
           bestName.given.count + bestName.family.count {
            bestName = (contact.givenName, contact.familyName)
        }
        
        // Собрать уникальные телефоны
        for phone in contact.phoneNumbers {
            if !allPhones.contains(where: { 
                normalizePhoneNumber($0.value.stringValue) == 
                normalizePhoneNumber(phone.value.stringValue) 
            }) {
                allPhones.append(phone)
            }
        }
        
        // Собрать уникальные email
        for email in contact.emailAddresses {
            if !allEmails.contains(where: { 
                ($0.value as String).lowercased() == (email.value as String).lowercased() 
            }) {
                allEmails.append(email)
            }
        }
    }
    
    // 2. Заполнить объединённый контакт
    merged.givenName = bestName.given
    merged.familyName = bestName.family
    merged.phoneNumbers = allPhones
    merged.emailAddresses = allEmails
    
    // 3. Сохранить новый + удалить старые
    let request = CNSaveRequest()
    request.add(merged, toContainerWithIdentifier: nil)
    for contact in contacts {
        request.delete(contact.mutableCopy() as! CNMutableContact)
    }
    try store.execute(request)
}
```

---

## Требование 6: Резервное копирование

### Модели
```swift
struct ContactBackup: Identifiable, Codable {
    let id: UUID
    let date: Date
    let contacts: [BackupContact]
    var contactCount: Int { contacts.count }
}

struct BackupContact: Identifiable, Codable {
    let id: String                  // CNContact.identifier
    let givenName: String
    let familyName: String
    let organizationName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let note: String
}
```

### Создание бэкапа
```swift
func createBackup() {
    let contacts = fetchAllContacts()
    let backupContacts = contacts.map { BackupContact(from: $0) }
    let backup = ContactBackup(id: UUID(), date: Date(), contacts: backupContacts)
    
    var existing = loadBackups()
    existing.insert(backup, at: 0)
    
    // Хранить максимум 3 бэкапа (FIFO)
    if existing.count > 3 { existing = Array(existing.prefix(3)) }
    
    saveBackups(existing)
}
```

### Восстановление
```swift
func restoreContact(_ backupContact: BackupContact) throws {
    let mutable = CNMutableContact()
    mutable.givenName = backupContact.givenName
    mutable.familyName = backupContact.familyName
    mutable.organizationName = backupContact.organizationName
    mutable.phoneNumbers = backupContact.phoneNumbers.map {
        CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: $0))
    }
    mutable.emailAddresses = backupContact.emailAddresses.map {
        CNLabeledValue(label: CNLabelWork, value: $0 as NSString)
    }
    
    let request = CNSaveRequest()
    request.add(mutable, toContainerWithIdentifier: nil)
    try store.execute(request)
}
```

### Хранение
- UserDefaults, ключ: `"contact_backups"`
- JSON-кодирование через `JSONEncoder/JSONDecoder`
- Максимум 3 резервные копии

---

## Требование 7: UI экранов контактов

### ContactsCleanerView
- Карточки категорий: Duplicates, Similar Names, No Name, No Number
- Количество найденных проблем в каждой категории
- Кнопки "All Contacts" и "Backups"
- Кнопка "Scan" для запуска сканирования

### DuplicateContactsView
- Группы дубликатов с аватарами
- Чекбоксы для выбора
- Кнопка "Select All Duplicates"
- Кнопки "Merge" и "Delete"

### BackupsListView / BackupDetailView
- Список бэкапов с датой и количеством
- Детальный просмотр контактов в бэкапе
- Кнопка "Restore" для каждого контакта
- Кнопка "Restore All"

---

## Критерии приёмки

- [ ] Дубликаты находятся по совпадению нормализованного номера
- [ ] Похожие имена находятся по Levenshtein distance
- [ ] Нормализация поддерживает международные коды (US, RU, UK, DE, JP, BR, CN, IN)
- [ ] Merge корректно объединяет все данные контактов
- [ ] Бэкапы создаются перед массовым удалением
- [ ] Восстановление из бэкапа создаёт корректный контакт
- [ ] Максимум 3 бэкапа (FIFO)
- [ ] Лимит подписки проверяется при удалении
