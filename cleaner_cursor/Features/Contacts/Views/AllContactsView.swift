import SwiftUI
import Contacts

// MARK: - All Contacts View
/// Экран со списком всех контактов

struct AllContactsView: View {
    @ObservedObject private var service = ContactsService.shared
    @State private var searchText = ""
    
    private var filteredContacts: [CNContact] {
        let sorted = service.getSortedContacts()
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
            
            if service.contacts.isEmpty {
                emptyStateView
            } else {
                contactsList
            }
        }
        .navigationTitle("All Contacts")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search contacts")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Contacts")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your address book is empty")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Contacts List
    
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredContacts, id: \.identifier) { contact in
                    AllContactRow(contact: contact)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - All Contact Row

struct AllContactRow: View {
    let contact: CNContact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)
                
                if let imageData = contact.thumbnailImageData,
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
        let hash = abs(contact.identifier.hashValue)
        return colors[hash % colors.count].opacity(0.3)
    }
}

struct AllContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AllContactsView()
        }
    }
}

