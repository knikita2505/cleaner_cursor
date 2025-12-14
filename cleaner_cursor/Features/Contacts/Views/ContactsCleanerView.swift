import SwiftUI
import Contacts

// MARK: - Contacts Cleaner View
/// Главный экран модуля очистки контактов (8_contacts.md)

struct ContactsCleanerView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var hasAppeared = false
    
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
                } else {
                    print("❌ Not authorized, skipping scan")
                }
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Stats widget
                if !service.isScanning {
                    statsWidget
                }
                
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
        .overlay {
            if service.isScanning {
                scanningOverlay
            }
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(AppColors.neonBlue)
                
                Text("\(service.contacts.count) contacts")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 16) {
                statsItem(
                    count: totalIssues,
                    label: "Issues",
                    color: totalIssues > 0 ? AppColors.neonPink : .green
                )
                
                statsItem(
                    count: service.duplicateGroups.count,
                    label: "Duplicates",
                    color: .orange
                )
                
                statsItem(
                    count: service.noNameContacts.count + service.noNumberContacts.count,
                    label: "Incomplete",
                    color: .cyan
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func statsItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalIssues: Int {
        service.duplicateGroups.count +
        service.similarNameGroups.count +
        service.noNameContacts.count +
        service.noNumberContacts.count
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(spacing: 12) {
            // Duplicate Contacts
            NavigationLink(destination: DuplicateContactsView()) {
                ContactCategoryCard(
                    icon: "person.2.fill",
                    title: "Duplicate Contacts",
                    subtitle: "Contacts with same name, phone or email",
                    count: service.duplicateGroups.count,
                    color: .orange
                )
            }
            
            // Similar Names
            NavigationLink(destination: SimilarNamesView()) {
                ContactCategoryCard(
                    icon: "textformat.abc",
                    title: "Similar Names",
                    subtitle: "Names differing by 1-2 characters",
                    count: service.similarNameGroups.count,
                    color: .purple
                )
            }
            
            // No Name Contacts
            NavigationLink(destination: NoNameContactsView()) {
                ContactCategoryCard(
                    icon: "person.fill.questionmark",
                    title: "No Name Contacts",
                    subtitle: "Contacts with phone but no name",
                    count: service.noNameContacts.count,
                    color: .blue
                )
            }
            
            // No Number Contacts
            NavigationLink(destination: NoNumberContactsView()) {
                ContactCategoryCard(
                    icon: "phone.badge.minus",
                    title: "No Number Contacts",
                    subtitle: "Contacts with name but no phone",
                    count: service.noNumberContacts.count,
                    color: .cyan
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
    
    // MARK: - Scanning Overlay
    
    private var scanningOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.neonBlue)
            
            Text("Scanning contacts...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
}

// MARK: - Contact Category Card

struct ContactCategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let count: Int
    let color: Color
    
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
            
            // Count Badge
            if count > 0 {
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

