import Foundation
import Contacts

// MARK: - Contacts Service
/// Сервис для работы с контактами

@MainActor
final class ContactsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var isScanning: Bool = false
    
    // MARK: - Singleton
    
    static let shared = ContactsService()
    
    // MARK: - Private Properties
    
    private let contactStore = CNContactStore()
    
    // MARK: - Init
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            await MainActor.run {
                checkAuthorizationStatus()
            }
            return granted
        } catch {
            return false
        }
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    // MARK: - Fetch Contacts
    
    /// Получить все контакты
    func fetchAllContacts() throws -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]
        
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        
        return contacts
    }
    
    /// Найти дубликаты контактов
    func findDuplicateContacts() throws -> [[CNContact]] {
        let contacts = try fetchAllContacts()
        var duplicateGroups: [[CNContact]] = []
        var processedIds: Set<String> = []
        
        for contact in contacts {
            guard !processedIds.contains(contact.identifier) else { continue }
            
            var duplicates: [CNContact] = [contact]
            
            for otherContact in contacts {
                guard contact.identifier != otherContact.identifier,
                      !processedIds.contains(otherContact.identifier) else { continue }
                
                if areContactsDuplicates(contact, otherContact) {
                    duplicates.append(otherContact)
                    processedIds.insert(otherContact.identifier)
                }
            }
            
            if duplicates.count > 1 {
                duplicateGroups.append(duplicates)
            }
            
            processedIds.insert(contact.identifier)
        }
        
        return duplicateGroups
    }
    
    /// Найти пустые контакты
    func findEmptyContacts() throws -> [CNContact] {
        let contacts = try fetchAllContacts()
        
        return contacts.filter { contact in
            let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
            let hasPhone = !contact.phoneNumbers.isEmpty
            let hasEmail = !contact.emailAddresses.isEmpty
            
            return !hasName && !hasPhone && !hasEmail
        }
    }
    
    // MARK: - Contact Operations
    
    /// Объединить контакты
    func mergeContacts(_ contacts: [CNContact], into primaryContact: CNContact) throws {
        guard let mutableContact = primaryContact.mutableCopy() as? CNMutableContact else {
            throw ContactsServiceError.mergeFailed
        }
        
        // Merge phone numbers
        var allPhoneNumbers = mutableContact.phoneNumbers
        for contact in contacts where contact.identifier != primaryContact.identifier {
            for phoneNumber in contact.phoneNumbers {
                if !allPhoneNumbers.contains(where: { $0.value.stringValue == phoneNumber.value.stringValue }) {
                    allPhoneNumbers.append(phoneNumber)
                }
            }
        }
        mutableContact.phoneNumbers = allPhoneNumbers
        
        // Merge emails
        var allEmails = mutableContact.emailAddresses
        for contact in contacts where contact.identifier != primaryContact.identifier {
            for email in contact.emailAddresses {
                if !allEmails.contains(where: { $0.value as String == email.value as String }) {
                    allEmails.append(email)
                }
            }
        }
        mutableContact.emailAddresses = allEmails
        
        // Save merged contact
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        
        // Delete other contacts
        for contact in contacts where contact.identifier != primaryContact.identifier {
            if let mutableToDelete = contact.mutableCopy() as? CNMutableContact {
                saveRequest.delete(mutableToDelete)
            }
        }
        
        try contactStore.execute(saveRequest)
    }
    
    /// Удалить контакты
    func deleteContacts(_ contacts: [CNContact]) throws {
        let saveRequest = CNSaveRequest()
        
        for contact in contacts {
            if let mutableContact = contact.mutableCopy() as? CNMutableContact {
                saveRequest.delete(mutableContact)
            }
        }
        
        try contactStore.execute(saveRequest)
    }
    
    // MARK: - Private Methods
    
    private func areContactsDuplicates(_ contact1: CNContact, _ contact2: CNContact) -> Bool {
        // Check by phone number
        for phone1 in contact1.phoneNumbers {
            for phone2 in contact2.phoneNumbers {
                let normalized1 = normalizePhoneNumber(phone1.value.stringValue)
                let normalized2 = normalizePhoneNumber(phone2.value.stringValue)
                if normalized1 == normalized2 && !normalized1.isEmpty {
                    return true
                }
            }
        }
        
        // Check by name
        let name1 = "\(contact1.givenName) \(contact1.familyName)".lowercased().trimmingCharacters(in: .whitespaces)
        let name2 = "\(contact2.givenName) \(contact2.familyName)".lowercased().trimmingCharacters(in: .whitespaces)
        
        if !name1.isEmpty && name1 == name2 {
            return true
        }
        
        return false
    }
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        return phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    // MARK: - Statistics
    
    var totalContactsCount: Int {
        (try? fetchAllContacts().count) ?? 0
    }
    
    var duplicateContactsCount: Int {
        (try? findDuplicateContacts().reduce(0) { $0 + $1.count - 1 }) ?? 0
    }
    
    var emptyContactsCount: Int {
        (try? findEmptyContacts().count) ?? 0
    }
}

// MARK: - Contact Model

struct ContactItem: Identifiable, Hashable {
    let id: String
    let contact: CNContact
    let displayName: String
    let phoneNumbers: [String]
    let emails: [String]
    var isSelected: Bool = false
    
    init(contact: CNContact) {
        self.id = contact.identifier
        self.contact = contact
        self.displayName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        self.phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
        self.emails = contact.emailAddresses.map { $0.value as String }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContactItem, rhs: ContactItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Contacts Service Errors

enum ContactsServiceError: LocalizedError {
    case notAuthorized
    case fetchFailed
    case mergeFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Contacts access not authorized"
        case .fetchFailed: return "Failed to fetch contacts"
        case .mergeFailed: return "Failed to merge contacts"
        case .deleteFailed: return "Failed to delete contacts"
        }
    }
}

