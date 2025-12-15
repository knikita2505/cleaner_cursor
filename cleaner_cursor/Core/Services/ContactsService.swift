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
    
    // Резервные копии
    @Published var backups: [ContactBackup] = []
    private let maxBackups = 3
    
    // MARK: - Private
    
    private let store = CNContactStore()
    private let keysToFetch: [CNKeyDescriptor] = [
        // Basic identification
        CNContactIdentifierKey as CNKeyDescriptor,
        // Name fields
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactNicknameKey as CNKeyDescriptor,
        // Organization
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactDepartmentNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        // Contact info
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactUrlAddressesKey as CNKeyDescriptor,
        // Social & messaging
        CNContactSocialProfilesKey as CNKeyDescriptor,
        CNContactInstantMessageAddressesKey as CNKeyDescriptor,
        // Dates & relations
        CNContactDatesKey as CNKeyDescriptor,
        CNContactRelationsKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        // Images (Note: CNContactNoteKey requires special entitlement)
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactImageDataAvailableKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    // Backup storage
    private let backupsKey = "contact_backups"
    
    // MARK: - Init
    
    private init() {
        checkAuthorization()
        loadBackups()
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
    
    private func fetchContactsSync() -> [CNContact] {
        // Re-check authorization status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        print("📱 Authorization status before fetch: \(statusDescription(status))")
        
        guard status == .authorized else {
            print("❌ Not authorized to fetch contacts (status: \(statusDescription(status)))")
            return []
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
        
        return allContacts
    }
    
    // MARK: - Scan All Categories
    
    func scanAllCategories() async {
        print("🔍 Starting contacts scan...")
        
        await MainActor.run {
            self.isScanning = true
        }
        
        // Fetch and scan contacts on background thread, then update UI on main
        let results = await Task.detached(priority: .userInitiated) { [self] () -> ScanResults in
            let fetchedContacts = self.fetchContactsSync()
            print("📱 Total contacts loaded: \(fetchedContacts.count)")
            
            let duplicates = self.findDuplicatesSync(in: fetchedContacts)
            let duplicateIds = Set(duplicates.flatMap { $0.contacts.map { $0.identifier } })
            let similar = self.findSimilarNamesSync(in: fetchedContacts, excludeIds: duplicateIds)
            let noName = self.findNoNameContactsSync(in: fetchedContacts)
            let noNumber = self.findNoNumberContactsSync(in: fetchedContacts)
            
            return ScanResults(
                contacts: fetchedContacts,
                duplicates: duplicates,
                similar: similar,
                noName: noName,
                noNumber: noNumber
            )
        }.value
        
        await MainActor.run {
            self.contacts = results.contacts
            self.duplicateGroups = results.duplicates
            self.similarNameGroups = results.similar
            self.noNameContacts = results.noName
            self.noNumberContacts = results.noNumber
            self.isScanning = false
        }
        
        print("📊 Scan complete: \(results.duplicates.count) duplicates, \(results.similar.count) similar, \(results.noName.count) no name, \(results.noNumber.count) no number")
    }
    
    private struct ScanResults {
        let contacts: [CNContact]
        let duplicates: [ContactDuplicateGroup]
        let similar: [ContactSimilarGroup]
        let noName: [CNContact]
        let noNumber: [CNContact]
    }
    
    // MARK: - Find Duplicates (by phone number)
    
    private func findDuplicatesSync(in contacts: [CNContact]) -> [ContactDuplicateGroup] {
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
                
                // Sort contacts within group by name
                let sortedContacts = dedupedContacts.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
                
                result.append(ContactDuplicateGroup(
                    id: UUID().uuidString,
                    contacts: sortedContacts,
                    matchType: .phone,
                    matchValue: phone
                ))
                
                print("✅ Found duplicate group: \(sortedContacts.map { $0.displayName })")
            }
        }
        
        // Sort groups by first contact's name
        result.sort { group1, group2 in
            let name1 = group1.contacts.first?.displayName.lowercased() ?? ""
            let name2 = group2.contacts.first?.displayName.lowercased() ?? ""
            return name1 < name2
        }
        
        return result
    }
    
    // MARK: - Find Similar Names
    
    private func findSimilarNamesSync(in contacts: [CNContact], excludeIds: Set<String>) -> [ContactSimilarGroup] {
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
                // Sort contacts within group by name
                let sortedContacts = similarContacts.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
                result.append(ContactSimilarGroup(
                    id: UUID().uuidString,
                    contacts: sortedContacts
                ))
            }
        }
        
        // Sort groups by first contact's name
        result.sort { group1, group2 in
            let name1 = group1.contacts.first?.displayName.lowercased() ?? ""
            let name2 = group2.contacts.first?.displayName.lowercased() ?? ""
            return name1 < name2
        }
        
        return result
    }
    
    // MARK: - Find No Name Contacts
    
    private func findNoNameContactsSync(in contacts: [CNContact]) -> [CNContact] {
        let result = contacts.filter { contact in
            let hasGivenName = !contact.givenName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasFamilyName = !contact.familyName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasOrganization = !contact.organizationName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasName = hasGivenName || hasFamilyName || hasOrganization
            
            let hasPhone = !contact.phoneNumbers.isEmpty
            let hasEmail = !contact.emailAddresses.isEmpty
            
            return !hasName && (hasPhone || hasEmail)
        }
        // Sort by phone number
        let sorted = result.sorted { c1, c2 in
            let phone1 = c1.phoneNumbers.first?.value.stringValue ?? ""
            let phone2 = c2.phoneNumbers.first?.value.stringValue ?? ""
            return phone1 < phone2
        }
        print("📵 No name contacts: \(sorted.count)")
        return sorted
    }
    
    // MARK: - Find No Number Contacts
    
    private func findNoNumberContactsSync(in contacts: [CNContact]) -> [CNContact] {
        let result = contacts.filter { contact in
            let hasGivenName = !contact.givenName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasFamilyName = !contact.familyName.trimmingCharacters(in: .whitespaces).isEmpty
            let hasName = hasGivenName || hasFamilyName
            
            let hasPhone = !contact.phoneNumbers.isEmpty
            
            return hasName && !hasPhone
        }
        // Sort alphabetically by name
        let sorted = result.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
        print("📱 No number contacts: \(sorted.count)")
        return sorted
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
        
        // === Name fields - pick longest/best ===
        var bestGivenName = ""
        var bestFamilyName = ""
        var bestMiddleName = ""
        var bestNamePrefix = ""
        var bestNameSuffix = ""
        var bestNickname = ""
        var bestOrganization = ""
        var bestDepartment = ""
        var bestJobTitle = ""
        
        // === Collection fields - merge all unique ===
        var allPhones: [CNLabeledValue<CNPhoneNumber>] = []
        var allEmails: [CNLabeledValue<NSString>] = []
        var allAddresses: [CNLabeledValue<CNPostalAddress>] = []
        var allUrls: [CNLabeledValue<NSString>] = []
        var allSocialProfiles: [CNLabeledValue<CNSocialProfile>] = []
        var allInstantMessages: [CNLabeledValue<CNInstantMessageAddress>] = []
        var allDates: [CNLabeledValue<NSDateComponents>] = []
        var allRelations: [CNLabeledValue<CNContactRelation>] = []
        
        // === Single value fields ===
        var bestBirthday: DateComponents?
        var bestImage: Data?
        
        for contact in contactsToMerge {
            // Name fields - pick longest
            if contact.givenName.count > bestGivenName.count { bestGivenName = contact.givenName }
            if contact.familyName.count > bestFamilyName.count { bestFamilyName = contact.familyName }
            if contact.middleName.count > bestMiddleName.count { bestMiddleName = contact.middleName }
            if contact.namePrefix.count > bestNamePrefix.count { bestNamePrefix = contact.namePrefix }
            if contact.nameSuffix.count > bestNameSuffix.count { bestNameSuffix = contact.nameSuffix }
            if contact.nickname.count > bestNickname.count { bestNickname = contact.nickname }
            if contact.organizationName.count > bestOrganization.count { bestOrganization = contact.organizationName }
            if contact.departmentName.count > bestDepartment.count { bestDepartment = contact.departmentName }
            if contact.jobTitle.count > bestJobTitle.count { bestJobTitle = contact.jobTitle }
            // Note: contact.note requires special entitlement, skipped
            
            // Collection fields
            allPhones.append(contentsOf: contact.phoneNumbers)
            allEmails.append(contentsOf: contact.emailAddresses)
            allAddresses.append(contentsOf: contact.postalAddresses)
            allUrls.append(contentsOf: contact.urlAddresses)
            allSocialProfiles.append(contentsOf: contact.socialProfiles)
            allInstantMessages.append(contentsOf: contact.instantMessageAddresses)
            allDates.append(contentsOf: contact.dates)
            allRelations.append(contentsOf: contact.contactRelations)
            
            // Single values - pick first non-nil
            if bestBirthday == nil, let birthday = contact.birthday { bestBirthday = birthday }
            if bestImage == nil, contact.imageDataAvailable, let imageData = contact.imageData { bestImage = imageData }
        }
        
        // Set name fields
        mergedContact.givenName = bestGivenName
        mergedContact.familyName = bestFamilyName
        mergedContact.middleName = bestMiddleName
        mergedContact.namePrefix = bestNamePrefix
        mergedContact.nameSuffix = bestNameSuffix
        mergedContact.nickname = bestNickname
        mergedContact.organizationName = bestOrganization
        mergedContact.departmentName = bestDepartment
        mergedContact.jobTitle = bestJobTitle
        // Note: mergedContact.note requires special entitlement, skipped
        
        if let birthday = bestBirthday { mergedContact.birthday = birthday }
        if let imageData = bestImage { mergedContact.imageData = imageData }
        
        // Deduplicate phones by normalized number
        mergedContact.phoneNumbers = deduplicatePhones(allPhones)
        
        // Deduplicate emails
        var seenEmails = Set<String>()
        mergedContact.emailAddresses = allEmails.filter { email in
            let normalized = (email.value as String).lowercased().trimmingCharacters(in: .whitespaces)
            if seenEmails.contains(normalized) { return false }
            seenEmails.insert(normalized)
            return true
        }
        
        // Deduplicate addresses
        var seenAddresses = Set<String>()
        mergedContact.postalAddresses = allAddresses.filter { address in
            let key = "\(address.value.street)|\(address.value.city)|\(address.value.postalCode)"
            if seenAddresses.contains(key) { return false }
            seenAddresses.insert(key)
            return true
        }
        
        // Deduplicate URLs
        var seenUrls = Set<String>()
        mergedContact.urlAddresses = allUrls.filter { url in
            let normalized = (url.value as String).lowercased()
            if seenUrls.contains(normalized) { return false }
            seenUrls.insert(normalized)
            return true
        }
        
        // Social profiles, IMs, dates, relations - just add all unique
        mergedContact.socialProfiles = allSocialProfiles
        mergedContact.instantMessageAddresses = allInstantMessages
        mergedContact.dates = allDates
        mergedContact.contactRelations = allRelations
        
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
    
    /// Deduplicate phones - same digits = same phone, keep best formatted version
    private func deduplicatePhones(_ phones: [CNLabeledValue<CNPhoneNumber>]) -> [CNLabeledValue<CNPhoneNumber>] {
        var normalizedToPhone: [String: CNLabeledValue<CNPhoneNumber>] = [:]
        
        for phone in phones {
            let normalized = normalizePhoneNumber(phone.value.stringValue)
            if normalized.isEmpty { continue }
            
            // Keep the version with better formatting (longer original string usually means more formatting)
            if let existing = normalizedToPhone[normalized] {
                if phone.value.stringValue.count > existing.value.stringValue.count {
                    normalizedToPhone[normalized] = phone
                }
            } else {
                normalizedToPhone[normalized] = phone
            }
        }
        
        return Array(normalizedToPhone.values)
    }
    
    /// Get unique phone count for UI preview
    func getUniquePhoneCount(from contacts: [CNContact]) -> Int {
        var seen = Set<String>()
        for contact in contacts {
            for phone in contact.phoneNumbers {
                let normalized = normalizePhoneNumber(phone.value.stringValue)
                if !normalized.isEmpty {
                    seen.insert(normalized)
                }
            }
        }
        return seen.count
    }
    
    /// Get unique phones for UI preview
    func getUniquePhones(from contacts: [CNContact]) -> [String] {
        var normalizedToFormatted: [String: String] = [:]
        for contact in contacts {
            for phone in contact.phoneNumbers {
                let normalized = normalizePhoneNumber(phone.value.stringValue)
                if !normalized.isEmpty {
                    // Keep best formatted version
                    if let existing = normalizedToFormatted[normalized] {
                        if phone.value.stringValue.count > existing.count {
                            normalizedToFormatted[normalized] = phone.value.stringValue
                        }
                    } else {
                        normalizedToFormatted[normalized] = phone.value.stringValue
                    }
                }
            }
        }
        return Array(normalizedToFormatted.values).sorted()
    }
    
    /// Get unique emails for UI preview
    func getUniqueEmails(from contacts: [CNContact]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for contact in contacts {
            for email in contact.emailAddresses {
                let normalized = (email.value as String).lowercased().trimmingCharacters(in: .whitespaces)
                if !seen.contains(normalized) {
                    seen.insert(normalized)
                    result.append(email.value as String)
                }
            }
        }
        return result.sorted()
    }
    
    // MARK: - Helpers
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        // Extract only digits
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard !digits.isEmpty else { return "" }
        
        // === USA / Canada / NANP (+1) ===
        // Format: +1 XXX XXX XXXX (11 digits with country code)
        // Local: XXX XXX XXXX (10 digits)
        if digits.count == 11 && digits.hasPrefix("1") {
            return digits // Keep as is: 1XXXXXXXXXX
        }
        if digits.count == 10 {
            // Could be US local number, normalize to +1
            return "1" + digits
        }
        
        // === Russia (+7) ===
        // Format: +7 XXX XXX XX XX (11 digits)
        // Local with 8: 8 XXX XXX XX XX (11 digits, 8 = trunk code)
        if digits.count == 11 && digits.hasPrefix("8") {
            // Russian number starting with 8 -> normalize to 7
            return "7" + String(digits.dropFirst())
        }
        if digits.count == 11 && digits.hasPrefix("7") {
            return digits // Already normalized
        }
        
        // === Japan (+81) ===
        // Format: +81 XX XXXX XXXX (11-12 digits with country code)
        // Local: 0XX XXXX XXXX (10-11 digits, 0 = trunk code)
        if digits.count >= 10 && digits.count <= 11 && digits.hasPrefix("0") {
            // Japanese local -> add country code
            return "81" + String(digits.dropFirst())
        }
        if digits.hasPrefix("81") && digits.count >= 11 && digits.count <= 13 {
            return digits
        }
        
        // === Brazil (+55) ===
        // Format: +55 XX XXXXX XXXX (13 digits with country code, mobile)
        // Format: +55 XX XXXX XXXX (12 digits with country code, landline)
        // Local: 0XX XXXXX XXXX
        if digits.hasPrefix("55") && digits.count >= 12 && digits.count <= 13 {
            return digits
        }
        if digits.count >= 10 && digits.count <= 11 && digits.hasPrefix("0") {
            // Could be Brazilian local
            return "55" + String(digits.dropFirst())
        }
        
        // === UK (+44) ===
        if digits.hasPrefix("44") && digits.count >= 11 && digits.count <= 12 {
            return digits
        }
        if digits.count == 11 && digits.hasPrefix("0") {
            // UK local format 0XXXXXXXXXX
            return "44" + String(digits.dropFirst())
        }
        
        // === Germany (+49) ===
        if digits.hasPrefix("49") && digits.count >= 11 && digits.count <= 14 {
            return digits
        }
        
        // === China (+86) ===
        if digits.hasPrefix("86") && digits.count == 13 {
            return digits
        }
        if digits.count == 11 && digits.hasPrefix("1") {
            // Chinese mobile: 1XX XXXX XXXX
            return "86" + digits
        }
        
        // === India (+91) ===
        if digits.hasPrefix("91") && digits.count == 12 {
            return digits
        }
        
        // === Default: return digits as-is for comparison ===
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

// MARK: - Contact Backup Model

struct ContactBackup: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let contacts: [BackupContact]
    
    var contactCount: Int { contacts.count }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct BackupContact: Identifiable, Codable {
    let id: String
    let givenName: String
    let familyName: String
    let middleName: String
    let namePrefix: String
    let nameSuffix: String
    let nickname: String
    let organizationName: String
    let departmentName: String
    let jobTitle: String
    let phoneNumbers: [BackupPhone]
    let emailAddresses: [BackupEmail]
    let postalAddresses: [BackupAddress]
    let urlAddresses: [BackupURL]
    let socialProfiles: [BackupSocialProfile]
    let birthday: BackupDate?
    let imageData: Data?
    
    var displayName: String {
        let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            if !organizationName.isEmpty { return organizationName }
            if let phone = phoneNumbers.first { return phone.value }
            if let email = emailAddresses.first { return email.value }
            return "No Name"
        }
        return name
    }
    
    var primaryPhone: String? {
        phoneNumbers.first?.value
    }
    
    init(from contact: CNContact) {
        self.id = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.middleName = contact.middleName
        self.namePrefix = contact.namePrefix
        self.nameSuffix = contact.nameSuffix
        self.nickname = contact.nickname
        self.organizationName = contact.organizationName
        self.departmentName = contact.departmentName
        self.jobTitle = contact.jobTitle
        self.phoneNumbers = contact.phoneNumbers.map { BackupPhone(label: $0.label, value: $0.value.stringValue) }
        self.emailAddresses = contact.emailAddresses.map { BackupEmail(label: $0.label, value: $0.value as String) }
        self.postalAddresses = contact.postalAddresses.map { BackupAddress(from: $0) }
        self.urlAddresses = contact.urlAddresses.map { BackupURL(label: $0.label, value: $0.value as String) }
        self.socialProfiles = contact.socialProfiles.map { BackupSocialProfile(from: $0) }
        self.birthday = contact.birthday != nil ? BackupDate(from: contact.birthday!) : nil
        self.imageData = contact.imageData
    }
    
    func toCNContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.middleName = middleName
        contact.namePrefix = namePrefix
        contact.nameSuffix = nameSuffix
        contact.nickname = nickname
        contact.organizationName = organizationName
        contact.departmentName = departmentName
        contact.jobTitle = jobTitle
        contact.phoneNumbers = phoneNumbers.map { CNLabeledValue(label: $0.label, value: CNPhoneNumber(stringValue: $0.value)) }
        contact.emailAddresses = emailAddresses.map { CNLabeledValue(label: $0.label, value: $0.value as NSString) }
        contact.postalAddresses = postalAddresses.map { $0.toLabeledValue() }
        contact.urlAddresses = urlAddresses.map { CNLabeledValue(label: $0.label, value: $0.value as NSString) }
        contact.socialProfiles = socialProfiles.map { $0.toLabeledValue() }
        if let birthday = birthday { contact.birthday = birthday.toDateComponents() }
        if let imageData = imageData { contact.imageData = imageData }
        return contact
    }
}

struct BackupPhone: Codable {
    let label: String?
    let value: String
}

struct BackupEmail: Codable {
    let label: String?
    let value: String
}

struct BackupAddress: Codable {
    let label: String?
    let street: String
    let city: String
    let state: String
    let postalCode: String
    let country: String
    
    init(from labeled: CNLabeledValue<CNPostalAddress>) {
        self.label = labeled.label
        self.street = labeled.value.street
        self.city = labeled.value.city
        self.state = labeled.value.state
        self.postalCode = labeled.value.postalCode
        self.country = labeled.value.country
    }
    
    func toLabeledValue() -> CNLabeledValue<CNPostalAddress> {
        let address = CNMutablePostalAddress()
        address.street = street
        address.city = city
        address.state = state
        address.postalCode = postalCode
        address.country = country
        return CNLabeledValue(label: label, value: address)
    }
}

struct BackupURL: Codable {
    let label: String?
    let value: String
}

struct BackupSocialProfile: Codable {
    let label: String?
    let service: String
    let username: String
    let urlString: String
    
    init(from labeled: CNLabeledValue<CNSocialProfile>) {
        self.label = labeled.label
        self.service = labeled.value.service
        self.username = labeled.value.username
        self.urlString = labeled.value.urlString ?? ""
    }
    
    func toLabeledValue() -> CNLabeledValue<CNSocialProfile> {
        let profile = CNSocialProfile(urlString: urlString, username: username, userIdentifier: nil, service: service)
        return CNLabeledValue(label: label, value: profile)
    }
}

struct BackupDate: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
    
    init(from components: DateComponents) {
        self.year = components.year
        self.month = components.month
        self.day = components.day
    }
    
    func toDateComponents() -> DateComponents {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return components
    }
}

// MARK: - Backup Methods Extension

extension ContactsService {
    
    // MARK: - Load/Save Backups
    
    func loadBackups() {
        guard let data = UserDefaults.standard.data(forKey: backupsKey),
              let decoded = try? JSONDecoder().decode([ContactBackup].self, from: data) else {
            backups = []
            return
        }
        backups = decoded.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func saveBackups() {
        guard let data = try? JSONEncoder().encode(backups) else { return }
        UserDefaults.standard.set(data, forKey: backupsKey)
    }
    
    // MARK: - Create Backup
    
    func createBackup() async -> Bool {
        // Limit to 3 backups
        if backups.count >= maxBackups {
            // Remove oldest backup
            await MainActor.run {
                backups.removeLast()
            }
        }
        
        let backupContacts = contacts.map { BackupContact(from: $0) }
        let backup = ContactBackup(
            id: UUID().uuidString,
            createdAt: Date(),
            contacts: backupContacts
        )
        
        await MainActor.run {
            backups.insert(backup, at: 0)
            saveBackups()
        }
        
        return true
    }
    
    // MARK: - Delete Backup
    
    func deleteBackup(_ backup: ContactBackup) {
        backups.removeAll { $0.id == backup.id }
        saveBackups()
    }
    
    // MARK: - Restore Single Contact
    
    func restoreContact(_ backupContact: BackupContact) async throws {
        let newContact = backupContact.toCNContact()
        let saveRequest = CNSaveRequest()
        saveRequest.add(newContact, toContainerWithIdentifier: nil)
        try store.execute(saveRequest)
        await scanAllCategories()
    }
    
    // MARK: - Restore All Contacts from Backup
    
    func restoreAllContacts(from backup: ContactBackup) async throws {
        let saveRequest = CNSaveRequest()
        
        for backupContact in backup.contacts {
            let newContact = backupContact.toCNContact()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)
        }
        
        try store.execute(saveRequest)
        await scanAllCategories()
    }
    
    // MARK: - Get Sorted Contacts
    
    func getSortedContacts() -> [CNContact] {
        contacts.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
