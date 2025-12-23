import Foundation
import Photos
import UIKit
import LocalAuthentication
import Security

// MARK: - Secret Space Service
/// Сервис для управления секретным хранилищем (фото, видео, контакты)

@MainActor
final class SecretSpaceService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SecretSpaceService()
    
    // MARK: - Published Properties
    
    @Published var isUnlocked: Bool = false
    @Published var isPasscodeSet: Bool = false
    @Published var isFaceIDEnabled: Bool = false
    @Published var isLoadingData: Bool = false
    @Published var secretPhotos: [SecretMediaItem] = []
    @Published var secretVideos: [SecretMediaItem] = []
    @Published var secretContacts: [SecretContact] = []
    
    // MARK: - Private Properties
    
    private let keychainService = "com.cleaner.secretspace"
    private let passcodeKey = "passcode"
    private let faceIDKey = "faceIDEnabled"
    private let fileManager = FileManager.default
    
    private var secretFolderURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("SecretSpace", isDirectory: true)
    }
    
    private var photosURL: URL {
        secretFolderURL.appendingPathComponent("Photos", isDirectory: true)
    }
    
    private var videosURL: URL {
        secretFolderURL.appendingPathComponent("Videos", isDirectory: true)
    }
    
    private var contactsURL: URL {
        secretFolderURL.appendingPathComponent("contacts.json")
    }
    
    // MARK: - Init
    
    private init() {
        setupSecretFolder()
        loadSettings()
        // Загружаем данные в фоне после инициализации
        Task {
            await loadSecretDataAsync()
        }
    }
    
    // MARK: - Setup
    
    private func setupSecretFolder() {
        do {
            // Создаём основную папку
            if !fileManager.fileExists(atPath: secretFolderURL.path) {
                try fileManager.createDirectory(at: secretFolderURL, withIntermediateDirectories: true)
                // Исключаем из бэкапа iCloud
                var url = secretFolderURL
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            }
            
            // Создаём подпапки
            if !fileManager.fileExists(atPath: photosURL.path) {
                try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
            }
            
            if !fileManager.fileExists(atPath: videosURL.path) {
                try fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating secret folder: \(error)")
        }
    }
    
    private func loadSettings() {
        // Проверяем, установлен ли пароль
        isPasscodeSet = getPasscodeFromKeychain() != nil
        
        // Загружаем настройку Face ID
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: faceIDKey)
    }
    
    // MARK: - Computed Properties
    
    var totalHiddenCount: Int {
        secretPhotos.count + secretVideos.count + secretContacts.count
    }
    
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Passcode Management
    
    func setPasscode(_ passcode: String) -> Bool {
        let saved = savePasscodeToKeychain(passcode)
        if saved {
            isPasscodeSet = true
        }
        return saved
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedPasscode = getPasscodeFromKeychain() else {
            return false
        }
        return passcode == storedPasscode
    }
    
    func changePasscode(from oldPasscode: String, to newPasscode: String) -> Bool {
        guard verifyPasscode(oldPasscode) else {
            return false
        }
        return setPasscode(newPasscode)
    }
    
    func resetPasscode() {
        deletePasscodeFromKeychain()
        isPasscodeSet = false
        isFaceIDEnabled = false
        UserDefaults.standard.set(false, forKey: faceIDKey)
    }
    
    // MARK: - Keychain Operations
    
    private func savePasscodeToKeychain(_ passcode: String) -> Bool {
        guard let data = passcode.data(using: .utf8) else { return false }
        
        // Удаляем старый если есть
        deletePasscodeFromKeychain()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getPasscodeFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let passcode = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return passcode
    }
    
    private func deletePasscodeFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Face ID / Touch ID
    
    func setFaceIDEnabled(_ enabled: Bool) {
        isFaceIDEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: faceIDKey)
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard isFaceIDEnabled else { return false }
        
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
            if success {
                isUnlocked = true
            }
            return success
        } catch {
            return false
        }
    }
    
    // MARK: - Unlock / Lock
    
    func unlock() {
        isUnlocked = true
    }
    
    func lock() {
        isUnlocked = false
    }
    
    // MARK: - Load Secret Data
    
    /// Синхронная загрузка (для обновления после изменений)
    func loadSecretData() {
        loadSecretPhotosSync()
        loadSecretVideosSync()
        loadSecretContactsSync()
    }
    
    /// Асинхронная загрузка (для инициализации без блокировки UI)
    func loadSecretDataAsync() async {
        isLoadingData = true
        
        // Выполняем загрузку в background
        let (photos, videos, contacts) = await Task.detached(priority: .userInitiated) { [self] in
            let photos = self.loadPhotosFromDisk()
            let videos = self.loadVideosFromDisk()
            let contacts = self.loadContactsFromDisk()
            return (photos, videos, contacts)
        }.value
        
        // Обновляем на main thread
        self.secretPhotos = photos
        self.secretVideos = videos
        self.secretContacts = contacts
        self.isLoadingData = false
    }
    
    // MARK: - Background Loading (nonisolated)
    
    private nonisolated func loadPhotosFromDisk() -> [SecretMediaItem] {
        let photosPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SecretSpace/Photos", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: photosPath.path) else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: photosPath, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            return files.compactMap { url -> SecretMediaItem? in
                let ext = url.pathExtension.lowercased()
                let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp"]
                guard imageExtensions.contains(ext) else { return nil }
                return SecretMediaItem(fileURL: url, type: .photo)
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error loading secret photos: \(error)")
            return []
        }
    }
    
    private nonisolated func loadVideosFromDisk() -> [SecretMediaItem] {
        let videosPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SecretSpace/Videos", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: videosPath.path) else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: videosPath, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            return files.compactMap { url -> SecretMediaItem? in
                let ext = url.pathExtension.lowercased()
                let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv"]
                guard videoExtensions.contains(ext) else { return nil }
                return SecretMediaItem(fileURL: url, type: .video)
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error loading secret videos: \(error)")
            return []
        }
    }
    
    private nonisolated func loadContactsFromDisk() -> [SecretContact] {
        let contactsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SecretSpace/contacts.json")
        
        guard FileManager.default.fileExists(atPath: contactsPath.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: contactsPath)
            return try JSONDecoder().decode([SecretContact].self, from: data)
        } catch {
            print("Error loading secret contacts: \(error)")
            return []
        }
    }
    
    // MARK: - Sync Loading (for updates)
    
    private func loadSecretPhotosSync() {
        guard fileManager.fileExists(atPath: photosURL.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            secretPhotos = files.compactMap { url -> SecretMediaItem? in
                guard isImageFile(url) else { return nil }
                return SecretMediaItem(fileURL: url, type: .photo)
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error loading secret photos: \(error)")
        }
    }
    
    private func loadSecretVideosSync() {
        guard fileManager.fileExists(atPath: videosURL.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: videosURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            secretVideos = files.compactMap { url -> SecretMediaItem? in
                guard isVideoFile(url) else { return nil }
                return SecretMediaItem(fileURL: url, type: .video)
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error loading secret videos: \(error)")
        }
    }
    
    private func loadSecretContactsSync() {
        guard fileManager.fileExists(atPath: contactsURL.path) else {
            secretContacts = []
            return
        }
        
        do {
            let data = try Data(contentsOf: contactsURL)
            secretContacts = try JSONDecoder().decode([SecretContact].self, from: data)
        } catch {
            print("Error loading secret contacts: \(error)")
            secretContacts = []
        }
    }
    
    // MARK: - Save Secret Contacts
    
    private func saveSecretContacts() {
        do {
            let data = try JSONEncoder().encode(secretContacts)
            try data.write(to: contactsURL)
        } catch {
            print("Error saving secret contacts: \(error)")
        }
    }
    
    // MARK: - Photo / Video Operations
    
    /// Добавить фото из библиотеки в секретное хранилище
    func addPhotosFromLibrary(_ assets: [PHAsset], deleteOriginals: Bool = false) async throws -> Int {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
              PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            throw SecretSpaceError.photoLibraryNotAuthorized
        }
        
        var addedCount = 0
        
        for asset in assets {
            do {
                if asset.mediaType == .image {
                    try await savePhotoFromAsset(asset)
                } else if asset.mediaType == .video {
                    try await saveVideoFromAsset(asset)
                }
                addedCount += 1
            } catch {
                print("Error saving asset: \(error)")
            }
        }
        
        // Удаляем оригиналы если нужно
        if deleteOriginals && !assets.isEmpty {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }
        }
        
        // Перезагружаем данные
        loadSecretData()
        
        return addedCount
    }
    
    private func savePhotoFromAsset(_ asset: PHAsset) async throws {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, uti, _, info in
                guard let self = self, let imageData = data else {
                    continuation.resume(throwing: SecretSpaceError.failedToLoadImage)
                    return
                }
                
                let filename = "\(UUID().uuidString).\(self.getExtension(from: uti))"
                let fileURL = self.photosURL.appendingPathComponent(filename)
                
                do {
                    try imageData.write(to: fileURL)
                    
                    // Сохраняем дату создания
                    if let creationDate = asset.creationDate {
                        try self.fileManager.setAttributes([.creationDate: creationDate], ofItemAtPath: fileURL.path)
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func saveVideoFromAsset(_ asset: PHAsset) async throws {
        let filename = "\(UUID().uuidString).mp4"
        let fileURL = self.videosURL.appendingPathComponent(filename)
        
        // Используем requestExportSession для надежного экспорта видео
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestExportSession(
                forVideo: asset,
                options: options,
                exportPreset: AVAssetExportPresetHighestQuality
            ) { [weak self] exportSession, info in
                guard let exportSession = exportSession else {
                    // Fallback: попробуем через AVURLAsset
                    self?.saveVideoFallback(asset: asset, to: fileURL, continuation: continuation)
                    return
                }
                
                exportSession.outputURL = fileURL
                exportSession.outputFileType = .mp4
                
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        // Сохраняем дату создания
                        if let self = self, let creationDate = asset.creationDate {
                            try? self.fileManager.setAttributes([.creationDate: creationDate], ofItemAtPath: fileURL.path)
                        }
                        continuation.resume()
                        
                    case .failed, .cancelled:
                        let error = exportSession.error ?? SecretSpaceError.failedToLoadVideo
                        continuation.resume(throwing: error)
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// Fallback метод сохранения видео через AVURLAsset
    private func saveVideoFallback(asset: PHAsset, to fileURL: URL, continuation: CheckedContinuation<Void, Error>) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else {
                continuation.resume(throwing: SecretSpaceError.failedToLoadVideo)
                return
            }
            
            do {
                try self?.fileManager.copyItem(at: urlAsset.url, to: fileURL)
                
                if let self = self, let creationDate = asset.creationDate {
                    try? self.fileManager.setAttributes([.creationDate: creationDate], ofItemAtPath: fileURL.path)
                }
                
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Удалить элемент из секретного хранилища
    func deleteSecretItem(_ item: SecretMediaItem) throws {
        try fileManager.removeItem(at: item.fileURL)
        loadSecretData()
    }
    
    /// Удалить несколько элементов
    func deleteSecretItems(_ items: [SecretMediaItem]) throws {
        for item in items {
            try fileManager.removeItem(at: item.fileURL)
        }
        loadSecretData()
    }
    
    /// Получить UIImage для секретного фото
    nonisolated func loadImage(for item: SecretMediaItem) -> UIImage? {
        guard item.type == .photo,
              let data = try? Data(contentsOf: item.fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    /// Получить thumbnail для видео
    nonisolated func loadVideoThumbnail(for item: SecretMediaItem) -> UIImage? {
        guard item.type == .video else { return nil }
        
        let asset = AVAsset(url: item.fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    
    // MARK: - Contact Operations
    
    /// Добавить контакт
    func addContact(_ contact: SecretContact) {
        secretContacts.append(contact)
        saveSecretContacts()
    }
    
    /// Добавить контакт из данных
    func addContact(name: String, phone: String?, email: String?, notes: String?) {
        let contact = SecretContact(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            email: email,
            notes: notes,
            createdAt: Date()
        )
        addContact(contact)
    }
    
    /// Обновить контакт
    func updateContact(_ contact: SecretContact) {
        if let index = secretContacts.firstIndex(where: { $0.id == contact.id }) {
            secretContacts[index] = contact
            saveSecretContacts()
        }
    }
    
    /// Удалить контакт
    func deleteContact(_ contact: SecretContact) {
        secretContacts.removeAll { $0.id == contact.id }
        saveSecretContacts()
    }
    
    /// Удалить несколько контактов
    func deleteContacts(_ contacts: [SecretContact]) {
        let idsToDelete = Set(contacts.map { $0.id })
        secretContacts.removeAll { idsToDelete.contains($0.id) }
        saveSecretContacts()
    }
    
    /// Panic Button - удалить все данные
    func deleteAllSecretData() throws {
        // Удаляем все фото
        if fileManager.fileExists(atPath: photosURL.path) {
            try fileManager.removeItem(at: photosURL)
            try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }
        
        // Удаляем все видео
        if fileManager.fileExists(atPath: videosURL.path) {
            try fileManager.removeItem(at: videosURL)
            try fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
        }
        
        // Удаляем все контакты
        secretContacts = []
        saveSecretContacts()
        
        // Перезагружаем
        loadSecretData()
    }
    
    // MARK: - Helper Methods
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func getExtension(from uti: String?) -> String {
        guard let uti = uti else { return "jpg" }
        
        if uti.contains("heic") || uti.contains("heif") {
            return "heic"
        } else if uti.contains("png") {
            return "png"
        } else if uti.contains("gif") {
            return "gif"
        } else {
            return "jpg"
        }
    }
}

// MARK: - Models

struct SecretMediaItem: Identifiable, Hashable {
    let id: String
    let fileURL: URL
    let type: MediaType
    let creationDate: Date
    let fileSize: Int64
    
    enum MediaType: String, Codable {
        case photo
        case video
    }
    
    init(fileURL: URL, type: MediaType) {
        self.id = fileURL.lastPathComponent
        self.fileURL = fileURL
        self.type = type
        
        // Получаем атрибуты файла
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        self.creationDate = (attributes?[.creationDate] as? Date) ?? Date()
        self.fileSize = (attributes?[.size] as? Int64) ?? 0
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: creationDate)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SecretMediaItem, rhs: SecretMediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct SecretContact: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var phone: String?
    var email: String?
    var notes: String?
    let createdAt: Date
    
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

// MARK: - Biometric Type

enum BiometricType {
    case none
    case faceID
    case touchID
    
    var icon: String {
        switch self {
        case .none: return "lock.fill"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        }
    }
    
    var name: String {
        switch self {
        case .none: return "Biometric"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        }
    }
}

// MARK: - Errors

enum SecretSpaceError: Error, LocalizedError {
    case photoLibraryNotAuthorized
    case failedToLoadImage
    case failedToLoadVideo
    case failedToSave
    case passcodeNotSet
    case invalidPasscode
    
    var errorDescription: String? {
        switch self {
        case .photoLibraryNotAuthorized:
            return "Photo library access is required"
        case .failedToLoadImage:
            return "Failed to load image"
        case .failedToLoadVideo:
            return "Failed to load video"
        case .failedToSave:
            return "Failed to save file"
        case .passcodeNotSet:
            return "Passcode is not set"
        case .invalidPasscode:
            return "Invalid passcode"
        }
    }
}

import AVFoundation

