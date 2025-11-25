import Foundation
import LocalAuthentication
import Security

// MARK: - Secret Folder Service
/// Сервис для работы с секретной папкой

@MainActor
final class SecretFolderService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isUnlocked: Bool = false
    @Published var hasPasscode: Bool = false
    @Published var isBiometricsEnabled: Bool = false
    @Published var biometricType: LABiometryType = .none
    
    // MARK: - Singleton
    
    static let shared = SecretFolderService()
    
    // MARK: - Private Properties
    
    private let keychainService = "com.cleaner.secretfolder"
    private let passcodeKey = "userPasscode"
    private let biometricsKey = "biometricsEnabled"
    
    private let context = LAContext()
    
    // MARK: - Init
    
    private init() {
        checkPasscodeExists()
        checkBiometrics()
    }
    
    // MARK: - Passcode Management
    
    func setPasscode(_ passcode: String) throws {
        let data = passcode.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw SecretFolderError.keychainError
        }
        
        hasPasscode = true
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedPasscode = getStoredPasscode() else {
            return false
        }
        
        let isValid = passcode == storedPasscode
        if isValid {
            isUnlocked = true
        }
        return isValid
    }
    
    func removePasscode() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey
        ]
        
        SecItemDelete(query as CFDictionary)
        hasPasscode = false
        isUnlocked = false
    }
    
    private func getStoredPasscode() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: passcodeKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    private func checkPasscodeExists() {
        hasPasscode = getStoredPasscode() != nil
    }
    
    // MARK: - Biometrics
    
    func checkBiometrics() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
        
        isBiometricsEnabled = UserDefaults.standard.bool(forKey: biometricsKey)
    }
    
    func enableBiometrics(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: biometricsKey)
        isBiometricsEnabled = enabled
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard isBiometricsEnabled else { return false }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Secret Folder"
            )
            
            if success {
                await MainActor.run {
                    isUnlocked = true
                }
            }
            
            return success
        } catch {
            return false
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometrics"
        @unknown default: return "Biometrics"
        }
    }
    
    // MARK: - Lock/Unlock
    
    func lock() {
        isUnlocked = false
    }
    
    func unlock() {
        isUnlocked = true
    }
    
    // MARK: - Secret Files Storage
    
    private var secretFolderURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(".secretFolder", isDirectory: true)
    }
    
    func ensureSecretFolderExists() throws {
        guard let url = secretFolderURL else {
            throw SecretFolderError.folderNotFound
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            
            // Set hidden attribute
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = true
            var mutableURL = url
            try mutableURL.setResourceValues(resourceValues)
        }
    }
    
    func getSecretFiles() throws -> [URL] {
        guard let url = secretFolderURL else {
            throw SecretFolderError.folderNotFound
        }
        
        return try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
    }
    
    func addFileToSecretFolder(data: Data, filename: String) throws {
        try ensureSecretFolderExists()
        
        guard let url = secretFolderURL?.appendingPathComponent(filename) else {
            throw SecretFolderError.folderNotFound
        }
        
        try data.write(to: url)
    }
    
    func removeFileFromSecretFolder(filename: String) throws {
        guard let url = secretFolderURL?.appendingPathComponent(filename) else {
            throw SecretFolderError.folderNotFound
        }
        
        try FileManager.default.removeItem(at: url)
    }
    
    var secretFilesCount: Int {
        (try? getSecretFiles().count) ?? 0
    }
}

// MARK: - Secret Folder Errors

enum SecretFolderError: LocalizedError {
    case keychainError
    case folderNotFound
    case fileNotFound
    case biometricsNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .keychainError: return "Failed to save to Keychain"
        case .folderNotFound: return "Secret folder not found"
        case .fileNotFound: return "File not found"
        case .biometricsNotAvailable: return "Biometrics not available"
        }
    }
}

