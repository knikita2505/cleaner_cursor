import SwiftUI
import Contacts

// MARK: - Similar Names View
/// Экран контактов с похожими именами (8_contacts.md)

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
                ForEach(service.similarNameGroups) { group in
                    SimilarGroupCard(group: group) {
                        selectedGroup = group
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Similar Group Card

struct SimilarGroupCard: View {
    let group: ContactSimilarGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    Text("Review")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.neonBlue)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(AppColors.neonBlue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Similar Names Action Sheet

struct SimilarNamesActionSheet: View {
    let group: ContactSimilarGroup
    @ObservedObject private var service = ContactsService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isMerging = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                            
                            Text("These contacts have similar names")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 16)
                        
                        // Contacts
                        ForEach(group.contacts, id: \.identifier) { contact in
                            ContactDetailCard(contact: contact)
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            // Merge button
                            Button {
                                Task {
                                    isMerging = true
                                    do {
                                        try await service.mergeContacts(group.contacts)
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                    isMerging = false
                                }
                            } label: {
                                HStack {
                                    if isMerging {
                                        ProgressView()
                                            .tint(.black)
                                    } else {
                                        Image(systemName: "arrow.triangle.merge")
                                    }
                                    Text("Merge Into One")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.neonBlue)
                                .cornerRadius(12)
                            }
                            .disabled(isMerging)
                            
                            // Keep separate
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
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Review")
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
        }
    }
}

struct SimilarNamesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SimilarNamesView()
        }
    }
}

