import SwiftUI
import Contacts
import UIKit

// MARK: - Duplicate Contacts View
/// Экран дубликатов контактов (8_contacts.md)

struct DuplicateContactsView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var selectedGroup: ContactDuplicateGroup?
    @State private var quickMergeGroup: ContactDuplicateGroup?
    @State private var isMergingAll = false
    @State private var isMergingSingle = false
    @State private var showMergeAllConfirm = false
    @State private var showQuickMergeConfirm = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if service.duplicateGroups.isEmpty {
                emptyStateView
            } else {
                groupsList
            }
        }
        .navigationTitle("Duplicates")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !service.duplicateGroups.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Merge All") {
                        showMergeAllConfirm = true
                    }
                    .foregroundColor(AppColors.neonBlue)
                }
            }
        }
        .sheet(item: $selectedGroup) { group in
            MergeContactsSheet(group: group)
        }
        .confirmationDialog(
            "Merge All Duplicates?",
            isPresented: $showMergeAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Merge \(service.duplicateGroups.count) Groups", role: .destructive) {
                Task { await mergeAllGroups() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will merge all duplicate groups into single contacts. This action cannot be undone.")
        }
        .confirmationDialog(
            "Quick Merge?",
            isPresented: $showQuickMergeConfirm,
            titleVisibility: .visible
        ) {
            Button("Merge \(quickMergeGroup?.contacts.count ?? 0) Contacts", role: .destructive) {
                if let group = quickMergeGroup {
                    Task { await quickMerge(group: group) }
                }
            }
            Button("Cancel", role: .cancel) {
                quickMergeGroup = nil
            }
        } message: {
            if let group = quickMergeGroup {
                Text("Merge \(group.contacts.count) contacts into one? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isMergingAll || isMergingSingle {
                mergingOverlay
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Duplicates Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your contacts are clean!")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary header
                summaryHeader
                
                // Groups
                LazyVStack(spacing: 16) {
                    ForEach(service.duplicateGroups) { group in
                        DuplicateGroupCard(
                            group: group,
                            onTap: {
                                selectedGroup = group
                            },
                            onQuickMerge: {
                                quickMergeGroup = group
                                showQuickMergeConfirm = true
                            }
                        )
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var summaryHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(service.duplicateGroups.count) duplicate groups")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(totalDuplicateContacts) contacts can be merged")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var totalDuplicateContacts: Int {
        service.duplicateGroups.reduce(0) { $0 + $1.contacts.count }
    }
    
    private var mergingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.neonBlue)
                
                Text("Merging contacts...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func mergeAllGroups() async {
        isMergingAll = true
        
        for group in service.duplicateGroups {
            do {
                try await service.mergeContacts(group.contacts)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                break
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isMergingAll = false
    }
    
    private func quickMerge(group: ContactDuplicateGroup) async {
        isMergingSingle = true
        
        do {
            try await service.mergeContacts(group.contacts)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        quickMergeGroup = nil
        isMergingSingle = false
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: ContactDuplicateGroup
    let onTap: () -> Void
    let onQuickMerge: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Match type badge
                HStack(spacing: 6) {
                    Image(systemName: matchIcon)
                        .font(.caption)
                    Text(group.matchType.description)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                
                Spacer()
                
                Text("\(group.contacts.count) contacts")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Contacts preview (stacked avatars)
            HStack(spacing: -12) {
                ForEach(Array(group.contacts.prefix(4).enumerated()), id: \.element.identifier) { index, contact in
                    ContactAvatar(contact: contact, size: 44)
                        .overlay(
                            Circle()
                                .stroke(AppColors.backgroundPrimary, lineWidth: 2)
                        )
                        .zIndex(Double(4 - index))
                }
                
                if group.contacts.count > 4 {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                        
                        Text("+\(group.contacts.count - 4)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(AppColors.backgroundPrimary, lineWidth: 2)
                    )
                }
                
                Spacer()
            }
            
            // Names list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(group.contacts.prefix(3), id: \.identifier) { contact in
                    HStack(spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange)
                        Text(contact.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                
                if group.contacts.count > 3 {
                    Text("  +\(group.contacts.count - 3) more...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Quick Merge button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onQuickMerge()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.caption)
                        Text("Quick Merge")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppColors.neonBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.neonBlue.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Review label (tap anywhere on card to open)
                HStack(spacing: 4) {
                    Text("Review & Merge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(AppColors.neonBlue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
    }
    
    private var matchIcon: String {
        switch group.matchType {
        case .phone: return "phone.fill"
        case .email: return "envelope.fill"
        case .name: return "person.fill"
        }
    }
}

// MARK: - Contact Avatar

struct ContactAvatar: View {
    let contact: CNContact
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: size, height: size)
            
            if let imageData = contact.thumbnailImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var initials: String {
        let first = contact.givenName.prefix(1)
        let last = contact.familyName.prefix(1)
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .indigo]
        let hash = abs(contact.identifier.hashValue)
        return colors[hash % colors.count].opacity(0.6)
    }
}

// MARK: - Merge Contacts Sheet

struct MergeContactsSheet: View {
    let group: ContactDuplicateGroup
    @ObservedObject private var service = ContactsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isMerging = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var contactToDelete: CNContact?
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Info banner
                        infoBanner
                        
                        // Contacts comparison
                        ForEach(group.contacts, id: \.identifier) { contact in
                            ContactDetailCardWithActions(
                                contact: contact,
                                canDelete: group.contacts.count > 1,
                                onDelete: {
                                    contactToDelete = contact
                                    showDeleteConfirm = true
                                }
                            )
                        }
                        
                        // Merged result preview
                        mergedPreview
                        
                        // Actions
                        actionsSection
                        
                        Spacer(minLength: 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Review & Merge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete this contact?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let contact = contactToDelete {
                        Task { await deleteContact(contact) }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let contact = contactToDelete {
                    Text("Delete \(contact.displayName)? This cannot be undone.")
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Stacked avatars
            HStack(spacing: -16) {
                ForEach(Array(group.contacts.prefix(3).enumerated()), id: \.element.identifier) { index, contact in
                    ContactAvatar(contact: contact, size: 56)
                        .overlay(
                            Circle()
                                .stroke(AppColors.backgroundPrimary, lineWidth: 3)
                        )
                        .zIndex(Double(3 - index))
                }
            }
            
            Text("\(group.contacts.count) Duplicate Contacts")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(group.matchType.description)
                .font(.caption)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.neonBlue)
            
            Text("Merging will combine all data into one contact and delete the others.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(AppColors.neonBlue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mergedPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundColor(.green)
                Text("Merged Result")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Best name
                let bestName = findBestName()
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text(bestName.isEmpty ? "No Name" : bestName)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                
                // All unique phones
                let phones = getAllUniquePhones()
                if !phones.isEmpty {
                    ForEach(phones, id: \.self) { phone in
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text(phone)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // All unique emails
                let emails = getAllUniqueEmails()
                if !emails.isEmpty {
                    ForEach(emails, id: \.self) { email in
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text(email)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Merge button
            Button {
                Task {
                    await mergeContacts()
                }
            } label: {
                HStack {
                    if isMerging {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "arrow.triangle.merge")
                    }
                    Text("Merge All Into One")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.neonBlue)
                .cornerRadius(12)
            }
            .disabled(isMerging || isDeleting)
            
            // Keep separate button
            Button {
                dismiss()
            } label: {
                Text("Keep Separate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func findBestName() -> String {
        var bestGiven = ""
        var bestFamily = ""
        
        for contact in group.contacts {
            if contact.givenName.count > bestGiven.count {
                bestGiven = contact.givenName
            }
            if contact.familyName.count > bestFamily.count {
                bestFamily = contact.familyName
            }
        }
        
        return "\(bestGiven) \(bestFamily)".trimmingCharacters(in: .whitespaces)
    }
    
    private func getAllUniquePhones() -> [String] {
        // Use service method that normalizes phone numbers correctly
        return service.getUniquePhones(from: group.contacts)
    }
    
    private func getAllUniqueEmails() -> [String] {
        // Use service method for consistent deduplication
        return service.getUniqueEmails(from: group.contacts)
    }
    
    private func mergeContacts() async {
        isMerging = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        do {
            try await service.mergeContacts(group.contacts)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isMerging = false
    }
    
    private func deleteContact(_ contact: CNContact) async {
        isDeleting = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        do {
            try await service.deleteContacts([contact])
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // If only one contact left, dismiss
            if group.contacts.count <= 2 {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isDeleting = false
    }
}

// MARK: - Contact Detail Card With Actions

struct ContactDetailCardWithActions: View {
    let contact: CNContact
    let canDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with avatar and delete button
            HStack(spacing: 12) {
                ContactAvatar(contact: contact, size: 50)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !contact.organizationName.isEmpty {
                        Text(contact.organizationName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Phone numbers
            ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phone.value.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        if let label = phone.label {
                            Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Emails
            ForEach(contact.emailAddresses, id: \.identifier) { email in
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text(email.value as String)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            // No contact info message
            if contact.phoneNumbers.isEmpty && contact.emailAddresses.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    Text("No phone or email")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Contact Detail Card (Simple)

struct ContactDetailCard: View {
    let contact: CNContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with avatar
            HStack(spacing: 12) {
                ContactAvatar(contact: contact, size: 50)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !contact.organizationName.isEmpty {
                        Text(contact.organizationName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Phone numbers
            ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phone.value.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        if let label = phone.label {
                            Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Emails
            ForEach(contact.emailAddresses, id: \.identifier) { email in
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text(email.value as String)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

struct DuplicateContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DuplicateContactsView()
        }
    }
}
