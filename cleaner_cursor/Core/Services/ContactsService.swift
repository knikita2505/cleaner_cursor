import Foundation
import Contacts

// MARK: - Contacts Service
/// Сервис для работы с контактами (8_contacts.md)

final class ContactsService: ObservableObject {
    
    static let shared = ContactsService()
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var isScanning = false
    @Published var contacts: [CNContact] = []
    
    // Категории контактов (4 категории)
    @Published var duplicateGroups: [ContactDuplicateGroup] = []
    @Published var similarNameGroups: [ContactSimilarGroup] = []
    @Published var noNameContacts: [CNContact] = []
    @Published var noNumberContacts: [CNContact] = []
    
    // MARK: - Private
    
    private let store = CNContactStore()
    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    // MARK: - Init
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        let authorized = (status == .authorized)
        DispatchQueue.main.async {
            self.isAuthorized = authorized
        }
        print("📱 Contacts authorization status: \(statusDescription(status)), isAuthorized: \(authorized)")
    }
    
    func requestAuthorization() async -> Bool {
        // First check current status
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        print("📱 Current contacts status before request: \(statusDescription(currentStatus))")
        
        if currentStatus == .authorized {
            await MainActor.run {
                self.isAuthorized = true
            }
            return true
        }
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.isAuthorized = granted
            }
            print("📱 Contacts access granted: \(granted)")
            
            // Re-check status after request
            let newStatus = CNContactStore.authorizationStatus(for: .contacts)
            print("📱 Contacts status after request: \(statusDescription(newStatus))")
            
            return granted
        } catch {
            print("❌ Contacts authorization error: \(error)")
            await MainActor.run {
                self.isAuthorized = false
            }
            return false
        }
    }
    
    private func statusDescription(_ status: CNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
    
    // MARK: - Fetch Contacts
    
    func fetchContacts() {
        // Re-check authorization status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        print("📱 Authorization status before fetch: \(statusDescription(status))")
        
        guard status == .authorized else {
            print("❌ Not authorized to fetch contacts (status: \(statusDescription(status)))")
            return
        }
        
        var allContacts: [CNContact] = []
        
        // Try method 1: unifiedContacts with predicate (works better on some devices)
        do {
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier())
            allContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            print("📱 Method 1 (unifiedContacts): Fetched \(allContacts.count) contacts")
        } catch {
            print("⚠️ Method 1 failed: \(error.localizedDescription)")
            
            // Try method 2: enumerate all containers
            do {
                let containers = try store.containers(matching: nil)
                print("📦 Found \(containers.count) contact containers")
                
                for container in containers {
                    let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                    let containerContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                    allContacts.append(contentsOf: containerContacts)
                    print("📦 Container \(container.name): \(containerContacts.count) contacts")
                }
                print("📱 Method 2 (containers): Fetched \(allContacts.count) contacts total")
            } catch let error2 as NSError {
                print("❌ Method 2 failed: \(error2)")
                print("❌ Error domain: \(error2.domain), code: \(error2.code)")
                
                // Try method 3: enumerateContacts (original)
                let request = CNContactFetchRequest(keysToFetch: keysToFetch)
                do {
                    try store.enumerateContacts(with: request) { contact, _ in
                        allContacts.append(contact)
                    }
                    print("📱 Method 3 (enumerate): Fetched \(allContacts.count) contacts")
                } catch let error3 {
                    print("❌ Method 3 also failed: \(error3)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.contacts = allContacts
        }
    }
    
    // MARK: - Scan All Categories
    
    func scanAllCategories() async {
        print("🔍 Starting contacts scan...")
        
        await MainActor.run {
            self.isScanning = true
        }
        
        // Fetch contacts on background thread
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchContacts()
                continuation.resume()
            }
        }
        
        print("📱 Total contacts loaded: \(contacts.count)")
        
        // Now scan categories
        let duplicates = findDuplicatesSync()
        let similar = findSimilarNamesSync(excludeIds: Set(duplicates.flatMap { $0.contacts.map { $0.identifier } }))
        let noName = findNoNameContactsSync()
        let noNumber = findNoNumberContactsSync()
        
        await MainActor.run {
            self.duplicateGroups = duplicates
            self.similarNameGroups = similar
            self.noNameContacts = noName
            self.noNumberContacts = noNumber
            self.isScanning = false
        }
        
        print("📊 Scan complete: \(duplicates.count) duplicates, \(similar.count) similar, \(noName.count) no name, \(noNumber.count) no number")
    }
    
    // MARK: - Find Duplicates (by phone number)
    
    private func findDuplicatesSync() -> [ContactDuplicateGroup] {
        // Group contacts by normalized phone number
        var phoneToContacts: [String: [CNContact]] = [:]
        
        for contact in contacts {
            for phone in contact.phoneNumbers {
                let normalized = normalizePhoneNumber(phone.value.stringValue)
                // Only consider phone numbers with at least 6 digits
                if normalized.count >= 6 {
                    phoneToContacts[normalized, default: []].append(contact)
                }
            }
        }
        
        print("📞 Phone groups found: \(phoneToContacts.count)")
        
        // Find groups with more than 1 contact
        var result: [ContactDuplicateGroup] = []
        var usedContactIds = Set<String>()
        
        for (phone, groupContacts) in phoneToContacts {
            // Filter out already used contacts and dedupe
            var seenIds = Set<String>()
            let dedupedContacts = groupContacts.filter { contact in
                if usedContactIds.contains(contact.identifier) { return false }
                if seenIds.contains(contact.identifier) { return false }
                seenIds.insert(contact.identifier)
                return true
            }
            
            if dedupedContacts.count > 1 {
                // Mark as used
                dedupedContacts.forEach { usedContactIds.insert($0.identifier) }
                
                result.append(ContactDuplicateGroup(
                    id: UUID().uuidString,
                    contacts: dedupedContacts,
                    matchType: .phone,
                    matchValue: phone
                ))
                
                print("✅ Found duplicate group: \(dedupedContacts.map { $0.displayName })")
            }
        }
        
        return result
    }
    
    // MARK: - Find Similar Names
    
    private func findSimilarNamesSync(excludeIds: Set<String>) -> [ContactSimilarGroup] {
        var result: [ContactSimilarGroup] = []
        var processedIds = Set<String>()
        
        let contactsWithNames = contacts.filter { contact in
            let hasName = !contact.givenName.isEmpty || !contact.familyName.isEmpty
            return hasName && !excludeIds.contains(contact.identifier)
        }
        
        print("👥 Contacts with names (excluding duplicates): \(contactsWithNames.count)")
        
        for i in 0..<contactsWithNames.count {
            let contact1 = contactsWithNames[i]
            if processedIds.contains(contact1.identifier) { continue }
            
            let name1 = "\(contact1.givenName) \(contact1.familyName)".trimmingCharacters(in: .whitespaces).lowercased()
            if name1.isEmpty { continue }
            
            var similarContacts: [CNContact] = [contact1]
            
            for j in (i+1)..<contactsWithNames.count {
                let contact2 = contactsWithNames[j]
                if processedIds.contains(contact2.identifier) { continue }
                
                let name2 = "\(contact2.givenName) \(contact2.familyName)".trimmingCharacters(in: .whitespaces).lowercased()
                if name2.isEmpty { continue }
                
                let distance = levenshteinDistance(name1, name2)
                
                // Similar if distance is 1-3 characters
                let maxLength = max(name1.count, name2.count)
                let isSimilar = distance > 0 && distance <= 3 && Double(distance) / Double(maxLength) < 0.3
                
                if isSimilar {
                    similarContacts.append(contact2)
                    processedIds.insert(contact2.identifier)
                }
            }
            
            if similarContacts.count > 1 {
                processedIds.insert(contact1.identifier)
                result.append(ContactSimilarGroup(
                    id: UUID().uuidString,
                    contacts: similarContacts
                ))
            }
        }
        
        return result
    }
    
    // MARK: - Find No Name Contacts
    
    private func findNoNameContactsSync() -> [CNContact] {
        let result = contacts.filter { contact in
            let hasGivenName = !contact.givenName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasFamilyName = !contact.familyName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasOrganization = !contact.organizationName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasName = hasGivenName || hasFamilyName || hasOrganization
            
            let hasPhone = !contact.phoneNumbers.isEmpty
            let hasEmail = !contact.emailAddresses.isEmpty
            
            return !hasName && (hasPhone || hasEmail)
        }
        print("📵 No name contacts: \(result.count)")
        return result
    }
    
    // MARK: - Find No Number Contacts
    
    private func findNoNumberContactsSync() -> [CNContact] {
        let result = contacts.filter { contact in
            let hasGivenName = !contact.givenName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasFamilyName = !contact.familyName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasName = hasGivenName || hasFamilyName
            
            let hasPhone = !contact.phoneNumbers.isEmpty
            
            return hasName && !hasPhone
        }
        print("📱 No number contacts: \(result.count)")
        return result
    }
    
    // MARK: - Delete Contacts
    
    func deleteContacts(_ contactsToDelete: [CNContact]) async throws {
        let saveRequest = CNSaveRequest()
        
        for contact in contactsToDelete {
            if let mutableContact = contact.mutableCopy() as? CNMutableContact {
                saveRequest.delete(mutableContact)
            }
        }
        
        try store.execute(saveRequest)
        
        // Refresh
        await scanAllCategories()
    }
    
    // MARK: - Merge Contacts
    
    func mergeContacts(_ contactsToMerge: [CNContact]) async throws {
        guard contactsToMerge.count >= 2 else { return }
        
        let mergedContact = CNMutableContact()
        
        var bestGivenName = ""
        var bestFamilyName = ""
        var bestOrganization = ""
        var allPhones: [CNLabeledValue<CNPhoneNumber>] = []
        var allEmails: [CNLabeledValue<NSString>] = []
        
        for contact in contactsToMerge {
            if contact.givenName.count > bestGivenName.count {
                bestGivenName = contact.givenName
            }
            if contact.familyName.count > bestFamilyName.count {
                bestFamilyName = contact.familyName
            }
            if contact.organizationName.count > bestOrganization.count {
                bestOrganization = contact.organizationName
            }
            
            allPhones.append(contentsOf: contact.phoneNumbers)
            allEmails.append(contentsOf: contact.emailAddresses)
        }
        
        mergedContact.givenName = bestGivenName
        mergedContact.familyName = bestFamilyName
        mergedContact.organizationName = bestOrganization
        
        // Remove duplicate phones
        var seenPhones = Set<String>()
        mergedContact.phoneNumbers = allPhones.filter { phone in
            let normalized = normalizePhoneNumber(phone.value.stringValue)
            if seenPhones.contains(normalized) { return false }
            seenPhones.insert(normalized)
            return true
        }
        
        // Remove duplicate emails
        var seenEmails = Set<String>()
        mergedContact.emailAddresses = allEmails.filter { email in
            let normalized = (email.value as String).lowercased()
            if seenEmails.contains(normalized) { return false }
            seenEmails.insert(normalized)
            return true
        }
        
        let saveRequest = CNSaveRequest()
        
        for contact in contactsToMerge {
            if let mutable = contact.mutableCopy() as? CNMutableContact {
                saveRequest.delete(mutable)
            }
        }
        
        saveRequest.add(mergedContact, toContainerWithIdentifier: nil)
        
        try store.execute(saveRequest)
        
        await scanAllCategories()
    }
    
    // MARK: - Helpers
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Normalize Russian numbers: 8xxx -> 7xxx
        if digits.count == 11 && digits.hasPrefix("8") {
            return "7" + String(digits.dropFirst())
        }
        
        return digits
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[m][n]
    }
}

// MARK: - Models

struct ContactDuplicateGroup: Identifiable {
    let id: String
    let contacts: [CNContact]
    let matchType: DuplicateMatchType
    let matchValue: String
}

enum DuplicateMatchType {
    case phone
    case email
    case name
    
    var description: String {
        switch self {
        case .phone: return "Same phone number"
        case .email: return "Same email"
        case .name: return "Same name"
        }
    }
}

struct ContactSimilarGroup: Identifiable {
    let id: String
    let contacts: [CNContact]
}

// MARK: - CNContact Extensions

extension CNContact {
    var displayName: String {
        let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            if !organizationName.isEmpty {
                return organizationName
            }
            if let firstPhone = phoneNumbers.first {
                return firstPhone.value.stringValue
            }
            if let firstEmail = emailAddresses.first {
                return firstEmail.value as String
            }
            return "No Name"
        }
        return name
    }
    
    var primaryPhone: String? {
        phoneNumbers.first?.value.stringValue
    }
    
    var primaryEmail: String? {
        emailAddresses.first?.value as String?
    }
}
