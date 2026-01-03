import SwiftUI
import Contacts

// MARK: - No Name Contacts View
/// Экран контактов без имени (8_contacts.md)

struct NoNameContactsView: View {
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
            
            if service.noNameContacts.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
        .navigationTitle("No Name")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !service.noNameContacts.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(selectedContacts.isEmpty ? "Select All" : "Deselect") {
                        if selectedContacts.isEmpty {
                            selectedContacts = Set(service.noNameContacts.map { $0.identifier })
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
            
            Text("All your contacts have names")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Contacts List
    
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.noNameContacts, id: \.identifier) { contact in
                    NoNameContactRow(
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
        let contactsToDelete = service.noNameContacts.filter { selectedContacts.contains($0.identifier) }
        
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

// MARK: - No Name Contact Row

struct NoNameContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
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
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.blue)
                }
                
                // Phone number
                VStack(alignment: .leading, spacing: 4) {
                    if let phone = contact.primaryPhone {
                        Text(phone)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text("No name")
                        .font(.caption)
                        .foregroundColor(.gray)
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
}

struct NoNameContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoNameContactsView()
        }
    }
}

