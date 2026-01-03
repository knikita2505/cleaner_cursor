import SwiftUI
import Contacts

// MARK: - No Number Contacts View
/// Экран контактов без номера телефона (8_contacts.md)

struct NoNumberContactsView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var selectedContacts: Set<String> = []
    @State private var isDeleting = false
    @State private var showDeleteConfirm = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if service.noNumberContacts.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
        .navigationTitle("No Number")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !service.noNumberContacts.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(selectedContacts.isEmpty ? "Select All" : "Deselect") {
                        if selectedContacts.isEmpty {
                            selectedContacts = Set(service.noNumberContacts.map { $0.identifier })
                        } else {
                            selectedContacts.removeAll()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !selectedContacts.isEmpty {
                actionBar
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            "Delete \(selectedContacts.count) contacts?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteSelectedContacts() }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Good!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("All your contacts have phone numbers")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Contacts List
    
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.noNumberContacts, id: \.identifier) { contact in
                    NoNumberContactRow(
                        contact: contact,
                        isSelected: selectedContacts.contains(contact.identifier)
                    ) {
                        toggleSelection(contact)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, selectedContacts.isEmpty ? 0 : 80)
        }
    }
    
    // MARK: - Action Bar
    
    private var actionBar: some View {
        HStack(spacing: 16) {
            Button {
                showDeleteConfirm = true
            } label: {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text("Delete \(selectedContacts.count)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red)
                .cornerRadius(12)
            }
            .disabled(isDeleting)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    
    private func toggleSelection(_ contact: CNContact) {
        if selectedContacts.contains(contact.identifier) {
            selectedContacts.remove(contact.identifier)
        } else {
            selectedContacts.insert(contact.identifier)
        }
    }
    
    private func deleteSelectedContacts() async {
        isDeleting = true
        let contactsToDelete = service.noNumberContacts.filter { selectedContacts.contains($0.identifier) }
        
        do {
            try await service.deleteContacts(contactsToDelete)
            
            // Record to history
            CleaningHistoryService.shared.recordCleaning(
                type: .contacts,
                itemsCount: contactsToDelete.count,
                bytesFreed: 0
            )
            
            selectedContacts.removeAll()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isDeleting = false
    }
}

// MARK: - No Number Contact Row

struct NoNumberContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.neonBlue : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.neonBlue)
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.top, 4)
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if let imageData = contact.thumbnailImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Text(initials)
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    // Name
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Available fields
                    VStack(alignment: .leading, spacing: 4) {
                        // Emails
                        ForEach(emails, id: \.self) { email in
                            ContactFieldRow(icon: "envelope.fill", text: email, color: .blue)
                        }
                        
                        // Addresses
                        ForEach(addresses, id: \.self) { address in
                            ContactFieldRow(icon: "location.fill", text: address, color: .green)
                        }
                        
                        // URLs
                        ForEach(urls, id: \.self) { url in
                            ContactFieldRow(icon: "link", text: url, color: .purple)
                        }
                        
                        // Social profiles
                        ForEach(socialProfiles, id: \.self) { profile in
                            ContactFieldRow(icon: "bubble.left.fill", text: profile, color: .pink)
                        }
                        
                        // Organization
                        if let org = organization {
                            ContactFieldRow(icon: "building.2.fill", text: org, color: .orange)
                        }
                        
                        // If no additional fields
                        if emails.isEmpty && addresses.isEmpty && urls.isEmpty && socialProfiles.isEmpty && organization == nil {
                            Text("No additional info")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColors.neonBlue.opacity(0.1) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var initials: String {
        let first = contact.givenName.prefix(1)
        let last = contact.familyName.prefix(1)
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }
    
    private var emails: [String] {
        contact.emailAddresses.map { $0.value as String }
    }
    
    private var addresses: [String] {
        contact.postalAddresses.compactMap { labeled in
            let address = labeled.value
            let parts = [address.street, address.city, address.country].filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }
    
    private var urls: [String] {
        contact.urlAddresses.map { $0.value as String }
    }
    
    private var socialProfiles: [String] {
        contact.socialProfiles.map { "\($0.value.service): \($0.value.username)" }
    }
    
    private var organization: String? {
        let org = contact.organizationName
        let job = contact.jobTitle
        if !org.isEmpty && !job.isEmpty {
            return "\(job) @ \(org)"
        } else if !org.isEmpty {
            return org
        } else if !job.isEmpty {
            return job
        }
        return nil
    }
}

// MARK: - Contact Field Row

struct ContactFieldRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 14)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}

struct NoNumberContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoNumberContactsView()
        }
    }
}

