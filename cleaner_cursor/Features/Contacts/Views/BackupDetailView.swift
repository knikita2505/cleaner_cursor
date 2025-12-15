import SwiftUI

// MARK: - Backup Detail View
/// Экран детализации резервной копии с возможностью восстановления

struct BackupDetailView: View {
    let backup: ContactBackup
    @ObservedObject private var service = ContactsService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var isRestoring = false
    @State private var showRestoreAllConfirm = false
    @State private var contactToRestore: BackupContact?
    @State private var showRestoreOneConfirm = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    private var filteredContacts: [BackupContact] {
        let sorted = backup.contacts.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            ($0.primaryPhone?.contains(searchText) ?? false)
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header info
                headerInfo
                
                // Contacts list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredContacts) { contact in
                            BackupContactRow(contact: contact) {
                                contactToRestore = contact
                                showRestoreOneConfirm = true
                            }
                        }
                    }
                    .padding(16)
                }
            }
            
            if isRestoring {
                restoringOverlay
            }
        }
        .navigationTitle("Backup Details")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search contacts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Restore All") {
                    showRestoreAllConfirm = true
                }
                .foregroundColor(AppColors.neonBlue)
            }
        }
        .confirmationDialog(
            "Restore All Contacts?",
            isPresented: $showRestoreAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Restore \(backup.contactCount) Contacts") {
                Task { await restoreAll() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will add all \(backup.contactCount) contacts from this backup to your address book.")
        }
        .confirmationDialog(
            "Restore Contact?",
            isPresented: $showRestoreOneConfirm,
            titleVisibility: .visible
        ) {
            Button("Restore \(contactToRestore?.displayName ?? "Contact")") {
                if let contact = contactToRestore {
                    Task { await restoreOne(contact) }
                }
            }
            Button("Cancel", role: .cancel) {
                contactToRestore = nil
            }
        } message: {
            Text("This will add this contact to your address book.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - Header Info
    
    private var headerInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.green)
                
                Text(backup.formattedDate)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(backup.contactCount) contacts")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Restoring Overlay
    
    private var restoringOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.neonBlue)
                
                Text("Restoring contacts...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func restoreAll() async {
        isRestoring = true
        
        do {
            try await service.restoreAllContacts(from: backup)
            successMessage = "Successfully restored \(backup.contactCount) contacts"
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isRestoring = false
    }
    
    private func restoreOne(_ contact: BackupContact) async {
        isRestoring = true
        
        do {
            try await service.restoreContact(contact)
            successMessage = "Successfully restored \(contact.displayName)"
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        contactToRestore = nil
        isRestoring = false
    }
}

// MARK: - Backup Contact Row

struct BackupContactRow: View {
    let contact: BackupContact
    let onRestore: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)
                
                if let imageData = contact.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
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
            }
            
            Spacer()
            
            // Restore button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onRestore()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                    Text("Restore")
                        .font(.caption)
                }
                .foregroundColor(AppColors.neonBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.neonBlue.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var initials: String {
        let first = contact.givenName.prefix(1)
        let last = contact.familyName.prefix(1)
        let combined = "\(first)\(last)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]
        let hash = abs(contact.id.hashValue)
        return colors[hash % colors.count].opacity(0.3)
    }
}

struct BackupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackupDetailView(backup: ContactBackup(
                id: "1",
                createdAt: Date(),
                contacts: []
            ))
        }
    }
}

