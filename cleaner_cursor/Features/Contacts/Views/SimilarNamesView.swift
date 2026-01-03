import SwiftUI
import Contacts

// MARK: - Similar Names View
/// Экран контактов с похожими именами (8_contacts.md)
/// Предназначен для помощи в ручном удалении похожих контактов

struct SimilarNamesView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var selectedGroup: ContactSimilarGroup?
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if service.similarNameGroups.isEmpty {
                emptyStateView
            } else {
                groupsList
            }
        }
        .navigationTitle("Similar Names")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedGroup) { group in
            SimilarNamesActionSheet(group: group)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Similar Names Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("All your contacts have unique names")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Info banner
                infoBanner
                
                ForEach(service.similarNameGroups) { group in
                    SimilarGroupCard(group: group) {
                        selectedGroup = group
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.purple)
            
            Text("Review contacts with similar names and delete duplicates manually")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

// MARK: - Similar Group Card

struct SimilarGroupCard: View {
    let group: ContactSimilarGroup
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "textformat.abc")
                    .foregroundColor(.purple)
                
                Text("Similar names")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(group.contacts.count) contacts")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Names preview
            VStack(alignment: .leading, spacing: 8) {
                ForEach(group.contacts, id: \.identifier) { contact in
                    HStack {
                        Text("•")
                            .foregroundColor(.purple)
                        Text(contact.displayName)
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                }
            }
            
            // Action hint
            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Review & Delete")
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
}

// MARK: - Similar Names Action Sheet

struct SimilarNamesActionSheet: View {
    let group: ContactSimilarGroup
    @ObservedObject private var service = ContactsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var contactToDelete: CNContact?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Track remaining contacts in current group
    @State private var remainingContacts: [CNContact] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "textformat.abc")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                            
                            Text("Similar Names Detected")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Delete contacts you don't need")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 16)
                        
                        // Contacts with delete buttons
                        ForEach(remainingContacts, id: \.identifier) { contact in
                            SimilarContactCard(
                                contact: contact,
                                onDelete: {
                                    contactToDelete = contact
                                    showDeleteConfirm = true
                                }
                            )
                        }
                        
                        if remainingContacts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                
                                Text("All contacts reviewed")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(16)
                }
                
                if isDeleting {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.neonBlue)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Contact?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete \(contactToDelete?.displayName ?? "Contact")", role: .destructive) {
                    if let contact = contactToDelete {
                        Task { await deleteContact(contact) }
                    }
                }
                Button("Cancel", role: .cancel) {
                    contactToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                remainingContacts = group.contacts
            }
        }
    }
    
    private func deleteContact(_ contact: CNContact) async {
        isDeleting = true
        
        do {
            try await service.deleteContacts([contact])
            
            // Record to history
            CleaningHistoryService.shared.recordCleaning(
                type: .contacts,
                itemsCount: 1,
                bytesFreed: 0
            )
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Remove from local list
            remainingContacts.removeAll { $0.identifier == contact.identifier }
            
            // Auto-dismiss if only one contact left or none
            if remainingContacts.count <= 1 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        contactToDelete = nil
        isDeleting = false
    }
}

// MARK: - Similar Contact Card with Delete

struct SimilarContactCard: View {
    let contact: CNContact
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatar(contact: contact, size: 50)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let phone = contact.primaryPhone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let email = contact.primaryEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Delete button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SimilarNamesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SimilarNamesView()
        }
    }
}
