import SwiftUI
import Contacts

// MARK: - Contacts Cleaner View
/// Главный экран модуля очистки контактов (8_contacts.md)

struct ContactsCleanerView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var hasAppeared = false
    @State private var showBackupSuggestion = false
    
    private let backupSuggestionKey = "contacts_backup_suggested"
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if !service.isAuthorized {
                permissionRequiredView
            } else {
                mainContent
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            Task {
                // Check/request authorization
                if !service.isAuthorized {
                    let granted = await service.requestAuthorization()
                    print("📱 Authorization result: \(granted)")
                }
                
                // Scan if authorized
                if service.isAuthorized {
                    print("🔍 Starting scan...")
                    await service.scanAllCategories()
                    
                    // Show backup suggestion on first visit
                    if !UserDefaults.standard.bool(forKey: backupSuggestionKey) && service.contacts.count > 0 {
                        showBackupSuggestion = true
                    }
                } else {
                    print("❌ Not authorized, skipping scan")
                }
            }
        }
        .alert("Create Backup?", isPresented: $showBackupSuggestion) {
            Button("Create Backup") {
                UserDefaults.standard.set(true, forKey: backupSuggestionKey)
                Task { await service.createBackup() }
            }
            Button("Later", role: .cancel) {
                UserDefaults.standard.set(true, forKey: backupSuggestionKey)
            }
        } message: {
            Text("We recommend creating a backup of your \(service.contacts.count) contacts before making any changes.")
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Stats widget (always visible)
                statsWidget
                
                // Categories
                categoriesSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await service.scanAllCategories()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Keep your address book clean and organized")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stats Widget
    
    private var statsWidget: some View {
        VStack(spacing: 16) {
            // All contacts section
            allContactsSection
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Backups section
            backupsSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var allContactsSection: some View {
        NavigationLink(destination: AllContactsView()) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(AppColors.neonBlue)
                
                Text("\(service.contacts.count) contacts")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("View all")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(AppColors.neonBlue)
            }
        }
    }
    
    private var backupsSection: some View {
        NavigationLink(destination: BackupsListView()) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("\(service.backups.count) backups")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Manage")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(spacing: 12) {
            // Duplicates
            NavigationLink(destination: DuplicateContactsView()) {
                ContactCategoryCard(
                    icon: "person.2.fill",
                    title: "Duplicates",
                    subtitle: "Contacts with same name, phone or email",
                    count: service.duplicateGroups.count,
                    color: .orange,
                    isLoading: service.isScanning
                )
            }
            
            // Similar Names
            NavigationLink(destination: SimilarNamesView()) {
                ContactCategoryCard(
                    icon: "character.textbox",
                    title: "Similar Names",
                    subtitle: "Names differing by 1-2 characters",
                    count: service.similarNameGroups.count,
                    color: .purple,
                    isLoading: service.isScanning
                )
            }
            
            // No Name
            NavigationLink(destination: NoNameContactsView()) {
                ContactCategoryCard(
                    icon: "person.fill.questionmark",
                    title: "No Name",
                    subtitle: "Contacts with phone but no name",
                    count: service.noNameContacts.count,
                    color: .blue,
                    isLoading: service.isScanning
                )
            }
            
            // No Number
            NavigationLink(destination: NoNumberContactsView()) {
                ContactCategoryCard(
                    icon: "book.closed.fill",
                    title: "No Number",
                    subtitle: "Contacts with name but no phone",
                    count: service.noNumberContacts.count,
                    color: .cyan,
                    isLoading: service.isScanning
                )
            }
        }
    }
    
    // MARK: - Permission Required View
    
    private var permissionRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Contacts Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("To clean your address book, we need access to your contacts.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.neonBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
}

// MARK: - Contact Category Card

struct ContactCategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let count: Int
    let color: Color
    var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Count Badge or Loading
            if isLoading {
                ProgressView()
                    .tint(color)
            } else if count > 0 {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color)
                    .cornerRadius(12)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ContactsCleanerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContactsCleanerView()
        }
    }
}

