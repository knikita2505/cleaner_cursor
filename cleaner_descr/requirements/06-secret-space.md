# Требования: Secret Space

## Цель
Реализовать защищённое хранилище для фото, видео и контактов с PIN-кодом и биометрической аутентификацией.

---

## Требование 1: SecretSpaceService

### Класс
```swift
@MainActor
class SecretSpaceService: ObservableObject {
    static let shared = SecretSpaceService()
    
    @Published var isAuthenticated = false
    @Published var hasPasscode = false
    @Published var isBiometricEnabled = false
    @Published var biometricType: BiometricType = .none
    @Published var secretMediaItems: [SecretMediaItem] = []
    @Published var secretContacts: [SecretContact] = []
    @Published var isLoading = false
}
```

### Модели
```swift
struct SecretMediaItem: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let dateAdded: Date
    let mediaType: MediaType
    let fileSize: Int64
    var thumbnail: UIImage?
    
    enum MediaType: String, Codable {
        case photo
        case video
    }
}

struct SecretContact: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var email: String
    var notes: String
    let dateAdded: Date
}

enum BiometricType {
    case none
    case faceID
    case touchID
}

enum PasscodeMode {
    case create
    case confirm
    case enter
}
```

---

## Требование 2: Пароль (Keychain)

### Сохранение пароля
```swift
func setPasscode(_ passcode: String) {
    let data = passcode.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "secret_space_passcode",
        kSecAttrService as String: Bundle.main.bundleIdentifier!,
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary)  // Удалить существующий
    SecItemAdd(query as CFDictionary, nil)
    
    hasPasscode = true
}
```

### Проверка пароля
```swift
func verifyPasscode(_ passcode: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "secret_space_passcode",
        kSecAttrService as String: Bundle.main.bundleIdentifier!,
        kSecReturnData as String: true
    ]
    
    var result: AnyObject?
    SecItemCopyMatching(query as CFDictionary, &result)
    
    guard let data = result as? Data,
          let stored = String(data: data, encoding: .utf8) else { return false }
    
    return stored == passcode
}
```

---

## Требование 3: Биометрия (LocalAuthentication)

```swift
func authenticateWithBiometrics() async -> Bool {
    let context = LAContext()
    var error: NSError?
    
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        return false
    }
    
    do {
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock Secret Space"
        )
        if success { isAuthenticated = true }
        return success
    } catch {
        return false
    }
}

var biometricType: BiometricType {
    let context = LAContext()
    _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    switch context.biometryType {
    case .faceID: return .faceID
    case .touchID: return .touchID
    default: return .none
    }
}
```

---

## Требование 4: Хранение медиафайлов

### Директория
```swift
private var secretSpaceDirectory: URL {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let dir = documents.appendingPathComponent("SecretSpace", isDirectory: true)
    
    if !FileManager.default.fileExists(atPath: dir.path) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    
    // Исключить из iCloud backup
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    var mutableDir = dir
    try? mutableDir.setResourceValues(resourceValues)
    
    return dir
}
```

### Импорт фото из библиотеки
```swift
func addPhotosFromLibrary(_ assets: [PHAsset], deleteOriginals: Bool) async {
    for asset in assets {
        // 1. Запросить полноразмерное изображение
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        let image = try await requestImage(for: asset)
        
        // 2. Конвертировать в JPEG
        guard let data = image.jpegData(compressionQuality: 0.9) else { continue }
        
        // 3. Сохранить с уникальным именем
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = secretSpaceDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        
        // 4. Создать SecretMediaItem
        let item = SecretMediaItem(
            id: id,
            fileName: fileName,
            dateAdded: Date(),
            mediaType: .photo,
            fileSize: Int64(data.count)
        )
        secretMediaItems.append(item)
        
        // 5. Опционально удалить оригинал
        if deleteOriginals {
            try? await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }
        }
    }
    
    saveMetadata()
}
```

### Удаление
```swift
func deleteSecretItem(_ item: SecretMediaItem) {
    let fileURL = secretSpaceDirectory.appendingPathComponent(item.fileName)
    try? FileManager.default.removeItem(at: fileURL)
    secretMediaItems.removeAll { $0.id == item.id }
    saveMetadata()
}
```

### Panic Button
```swift
func deleteAllSecretData() {
    // 1. Удалить все файлы
    try? FileManager.default.removeItem(at: secretSpaceDirectory)
    
    // 2. Очистить метаданные
    secretMediaItems = []
    secretContacts = []
    saveMetadata()
    
    // 3. Удалить пароль из Keychain
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "secret_space_passcode"
    ]
    SecItemDelete(query as CFDictionary)
    
    hasPasscode = false
    isAuthenticated = false
}
```

---

## Требование 5: Секретные контакты

### CRUD операции
```swift
func addContact(_ contact: SecretContact) {
    secretContacts.append(contact)
    saveMetadata()
}

func updateContact(_ contact: SecretContact) {
    if let index = secretContacts.firstIndex(where: { $0.id == contact.id }) {
        secretContacts[index] = contact
        saveMetadata()
    }
}

func deleteContact(_ contact: SecretContact) {
    secretContacts.removeAll { $0.id == contact.id }
    saveMetadata()
}
```

### Хранение метаданных
```swift
private func saveMetadata() {
    // Сохранить secretContacts в UserDefaults (Codable)
    if let data = try? JSONEncoder().encode(secretContacts) {
        UserDefaults.standard.set(data, forKey: "secret_contacts")
    }
    
    // Сохранить метаданные медиа
    // (SecretMediaItem без thumbnail)
}
```

---

## Требование 6: UI экраны

### PasscodeView
- 4 кружка для отображения введённых цифр
- Цифровая клавиатура (1-9, 0, backspace)
- Кнопка биометрии (Face ID / Touch ID иконка)
- Анимация ошибки (shake)
- Два режима: create (с подтверждением) и enter

### SecretSpaceHomeView
- Две секции: "Photos & Videos" и "Contacts"
- Карточки с количеством элементов
- Кнопка настроек защиты
- Кнопка "Lock" для выхода

### SecretAlbumView
- Сетка фото/видео (LazyVGrid, 3 столбца)
- Кнопка "+" для импорта
- Множественный выбор и удаление
- Полноэкранный просмотр фото

### SecretContactsView
- Список контактов
- Кнопка "+" для добавления
- Свайп для удаления
- Детальный просмотр/редактирование

---

## Критерии приёмки

- [ ] PIN-код хранится в Keychain (не UserDefaults)
- [ ] Биометрия работает (Face ID / Touch ID)
- [ ] Файлы хранятся в Documents/SecretSpace/
- [ ] Директория исключена из iCloud backup
- [ ] Импорт фото из библиотеки работает
- [ ] Опция удаления оригинала при импорте
- [ ] Panic Button удаляет ВСЕ данные
- [ ] Секретные контакты НЕ видны в системной адресной книге
- [ ] При выходе из приложения — автоматическая блокировка
