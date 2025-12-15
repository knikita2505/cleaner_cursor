import SwiftUI

// MARK: - Backups List View
/// Экран со списком резервных копий контактов

struct BackupsListView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var isCreatingBackup = false
    @State private var showDeleteConfirm = false
    @State private var backupToDelete: ContactBackup?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Info banner
                    infoBanner
                    
                    // Create backup button
                    createBackupButton
                    
                    // Backups list
                    if service.backups.isEmpty {
                        emptyStateView
                    } else {
                        backupsList
                    }
                }
                .padding(16)
            }
            
            if isCreatingBackup {
                creatingOverlay
            }
        }
        .navigationTitle("Backups")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Delete Backup?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let backup = backupToDelete {
                    service.deleteBackup(backup)
                }
            }
            Button("Cancel", role: .cancel) {
                backupToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.neonBlue)
            
            Text("Maximum 3 backups. Creating a new backup when at limit will delete the oldest one.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.neonBlue.opacity(0.1))
        )
    }
    
    // MARK: - Create Backup Button
    
    private var createBackupButton: some View {
        Button {
            Task { await createBackup() }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Backup")
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.neonBlue)
            .cornerRadius(12)
        }
        .disabled(isCreatingBackup || service.contacts.isEmpty)
        .opacity(service.contacts.isEmpty ? 0.5 : 1)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Backups")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Create a backup to save your contacts")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Backups List
    
    private var backupsList: some View {
        VStack(spacing: 12) {
            ForEach(service.backups) { backup in
                BackupCard(
                    backup: backup,
                    onDelete: {
                        backupToDelete = backup
                        showDeleteConfirm = true
                    }
                )
            }
        }
    }
    
    // MARK: - Creating Overlay
    
    private var creatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.neonBlue)
                
                Text("Creating backup...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func createBackup() async {
        isCreatingBackup = true
        
        let success = await service.createBackup()
        
        if !success {
            errorMessage = "Failed to create backup"
            showError = true
        }
        
        isCreatingBackup = false
    }
}

// MARK: - Backup Card

struct BackupCard: View {
    let backup: ContactBackup
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: BackupDetailView(backup: backup)) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "externaldrive.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.formattedDate)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(backup.contactCount) contacts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.body)
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

struct BackupsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackupsListView()
        }
    }
}

