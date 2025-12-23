import SwiftUI
import Contacts

// MARK: - Secret Contacts View
/// Хранение приватных контактов согласно secret_contacts.md

struct SecretContactsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    
    @State private var showAddContact = false
    @State private var showImportContacts = false
    @State private var showDeleteConfirmation = false
    @State private var showPanicConfirmation = false
    @State private var selectedContact: SecretContact?
    @State private var searchText = ""
    @State private var selectedContacts: Set<String> = []
    @State private var isSelectionMode = false
    
    private var filteredContacts: [SecretContact] {
        if searchText.isEmpty {
            return secretService.secretContacts
        }
        return secretService.secretContacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.phone?.contains(searchText) ?? false) ||
            ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if secretService.secretContacts.isEmpty {
                    emptyStateView
                } else {
                    contactsListView
                }
            }
        }
        .navigationTitle("Secret Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showAddContact = true
                    } label: {
                        Label("Create New", systemImage: "plus")
                    }
                    
                    Button {
                        showImportContacts = true
                    } label: {
                        Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                    }
                    
                    if !secretService.secretContacts.isEmpty {
                        Divider()
                        
                        Button {
                            withAnimation {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedContacts.removeAll()
                                }
                            }
                        } label: {
                            Label(isSelectionMode ? "Cancel Selection" : "Select", systemImage: isSelectionMode ? "xmark" : "checkmark.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showPanicConfirmation = true
                        } label: {
                            Label("Delete All", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode && !selectedContacts.isEmpty {
                selectionBottomBar
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView()
        }
        .sheet(isPresented: $showImportContacts) {
            ImportContactsView()
        }
        .sheet(item: $selectedContact) { contact in
            ContactDetailView(contact: contact)
        }
        .alert("Delete Selected?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedContacts()
            }
        } message: {
            Text("These contacts will be permanently deleted.")
        }
        .alert("Delete All Contacts?", isPresented: $showPanicConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllContacts()
            }
        } message: {
            Text("This will permanently delete all secret contacts. This action cannot be undone.")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.statusSuccess.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            VStack(spacing: 8) {
                Text("No Secret Contacts")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Add contacts that only you can see.\nThey won't appear in your phone book.")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    showAddContact = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Create New Contact")
                            .font(AppFonts.subtitleM)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppGradients.ctaGradient)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button {
                    showImportContacts = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Import from Contacts")
                            .font(AppFonts.subtitleM)
                    }
                    .foregroundColor(AppColors.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentBlue.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(AppSpacing.screenPadding)
    }
    
    // MARK: - Contacts List
    
    private var contactsListView: some View {
        List {
            ForEach(filteredContacts) { contact in
                ContactRow(
                    contact: contact,
                    isSelected: selectedContacts.contains(contact.id),
                    isSelectionMode: isSelectionMode,
                    onTap: {
                        handleContactTap(contact)
                    }
                )
                .listRowBackground(AppColors.backgroundSecondary)
                .listRowSeparatorTint(AppColors.textTertiary.opacity(0.2))
            }
            .onDelete { indexSet in
                deleteContacts(at: indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Selection Bottom Bar
    
    private var selectionBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.textTertiary.opacity(0.2))
            
            HStack {
                Text("\(selectedContacts.count) selected")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.statusError)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Actions
    
    private func handleContactTap(_ contact: SecretContact) {
        if isSelectionMode {
            if selectedContacts.contains(contact.id) {
                selectedContacts.remove(contact.id)
            } else {
                selectedContacts.insert(contact.id)
            }
        } else {
            selectedContact = contact
        }
    }
    
    private func deleteContacts(at indexSet: IndexSet) {
        let contactsToDelete = indexSet.map { filteredContacts[$0] }
        secretService.deleteContacts(contactsToDelete)
        HapticManager.success()
    }
    
    private func deleteSelectedContacts() {
        let contactsToDelete = secretService.secretContacts.filter { selectedContacts.contains($0.id) }
        secretService.deleteContacts(contactsToDelete)
        selectedContacts.removeAll()
        isSelectionMode = false
        HapticManager.success()
    }
    
    private func deleteAllContacts() {
        secretService.secretContacts.removeAll()
        isSelectionMode = false
        HapticManager.success()
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: SecretContact
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            rowContent
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isSelectionMode {
                if let phone = contact.phone, !phone.isEmpty {
                    Button {
                        UIPasteboard.general.string = phone
                        HapticManager.success()
                    } label: {
                        Label("Copy Phone", systemImage: "doc.on.doc")
                    }
                }
                
                if let email = contact.email, !email.isEmpty {
                    Button {
                        UIPasteboard.general.string = email
                        HapticManager.success()
                    } label: {
                        Label("Copy Email", systemImage: "envelope")
                    }
                }
                
                Button {
                    UIPasteboard.general.string = contact.name
                    HapticManager.success()
                } label: {
                    Label("Copy Name", systemImage: "person")
                }
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 14) {
            // Selection indicator or Avatar
            if isSelectionMode {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.accentBlue : AppColors.textTertiary.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor(for: contact.name))
                    .frame(width: 44, height: 44)
                
                Text(contact.initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                if let phone = contact.phone, !phone.isEmpty {
                    Text(phone)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                } else if let email = contact.email, !email.isEmpty {
                    Text(email)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            if !isSelectionMode {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            AppColors.accentBlue,
            AppColors.accentPurple,
            AppColors.statusSuccess,
            AppColors.statusWarning,
            AppColors.accentLilac
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Add Contact View

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, phone, email, notes
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar preview
                        ZStack {
                            Circle()
                                .fill(AppColors.accentBlue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            if name.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColors.accentBlue)
                            } else {
                                Text(initials(for: name))
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(AppColors.accentBlue)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 16) {
                            formField(
                                icon: "person.fill",
                                placeholder: "Name",
                                text: $name,
                                field: .name
                            )
                            
                            formField(
                                icon: "phone.fill",
                                placeholder: "Phone",
                                text: $phone,
                                field: .phone,
                                keyboardType: .phonePad
                            )
                            
                            formField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                field: .email,
                                keyboardType: .emailAddress
                            )
                            
                            formField(
                                icon: "note.text",
                                placeholder: "Notes",
                                text: $notes,
                                field: .notes,
                                isMultiline: true
                            )
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func formField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboardType: UIKeyboardType = .default,
        isMultiline: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 24)
            
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(keyboardType)
                    .autocapitalization(field == .email ? .none : .words)
                    .focused($focusedField, equals: field)
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private func saveContact() {
        secretService.addContact(
            name: name,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            notes: notes.isEmpty ? nil : notes
        )
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Contact Detail View

struct ContactDetailView: View {
    let contact: SecretContact
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    @State private var isEditing = false
    @State private var editedContact: SecretContact
    @State private var showDeleteConfirmation = false
    
    init(contact: SecretContact) {
        self.contact = contact
        _editedContact = State(initialValue: contact)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(avatarColor.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Text(displayContact.initials)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(avatarColor)
                        }
                        .padding(.top, 20)
                        
                        // Name
                        if isEditing {
                            TextField("Name", text: $editedContact.name)
                                .font(AppFonts.titleL)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(displayContact.name)
                                .font(AppFonts.titleL)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        // Contact info
                        VStack(spacing: 2) {
                            if isEditing {
                                editableRow(icon: "phone.fill", placeholder: "Phone", text: Binding(
                                    get: { editedContact.phone ?? "" },
                                    set: { editedContact.phone = $0.isEmpty ? nil : $0 }
                                ))
                                
                                editableRow(icon: "envelope.fill", placeholder: "Email", text: Binding(
                                    get: { editedContact.email ?? "" },
                                    set: { editedContact.email = $0.isEmpty ? nil : $0 }
                                ))
                                
                                editableRow(icon: "note.text", placeholder: "Notes", text: Binding(
                                    get: { editedContact.notes ?? "" },
                                    set: { editedContact.notes = $0.isEmpty ? nil : $0 }
                                ))
                            } else {
                                if let phone = displayContact.phone, !phone.isEmpty {
                                    infoRow(icon: "phone.fill", title: "Phone", value: phone)
                                }
                                
                                if let email = displayContact.email, !email.isEmpty {
                                    infoRow(icon: "envelope.fill", title: "Email", value: email)
                                }
                                
                                if let notes = displayContact.notes, !notes.isEmpty {
                                    infoRow(icon: "note.text", title: "Notes", value: notes)
                                }
                            }
                        }
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(AppSpacing.cardRadius)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        
                        // Delete button
                        if !isEditing {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Contact")
                                }
                                .font(AppFonts.subtitleM)
                                .foregroundColor(AppColors.statusError)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.statusError.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, AppSpacing.screenPadding)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            editedContact = contact
                            isEditing = false
                        }
                        .foregroundColor(AppColors.textTertiary)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    }
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(isEditing && editedContact.name.isEmpty)
                }
            }
            .alert("Delete Contact?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteContact()
                }
            } message: {
                Text("This contact will be permanently deleted.")
            }
        }
    }
    
    private var displayContact: SecretContact {
        isEditing ? editedContact : contact
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [
            AppColors.accentBlue,
            AppColors.accentPurple,
            AppColors.statusSuccess,
            AppColors.statusWarning,
            AppColors.accentLilac
        ]
        let hash = abs(contact.name.hashValue)
        return colors[hash % colors.count]
    }
    
    @State private var copiedField: String?
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        Button {
            copyToClipboard(value, field: title)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentBlue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(value)
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // Copied indicator
                if copiedField == title {
                    Text("Copied")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusSuccess)
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary.opacity(0.5))
                }
            }
            .padding(AppSpacing.containerPadding)
        }
        .buttonStyle(.plain)
    }
    
    private func copyToClipboard(_ value: String, field: String) {
        UIPasteboard.general.string = value
        HapticManager.success()
        
        withAnimation {
            copiedField = field
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                if copiedField == field {
                    copiedField = nil
                }
            }
        }
    }
    
    private func editableRow(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .font(AppFonts.bodyL)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppSpacing.containerPadding)
    }
    
    private func saveChanges() {
        secretService.updateContact(editedContact)
        isEditing = false
        HapticManager.success()
    }
    
    private func deleteContact() {
        secretService.deleteContact(contact)
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Import Contacts View

struct ImportContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    
    @State private var contacts: [CNContact] = []
    @State private var selectedContacts: Set<String> = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            let fullName = "\($0.givenName) \($0.familyName)"
            return fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(AppColors.accentBlue)
                } else if authorizationStatus != .authorized {
                    noAccessView
                } else if contacts.isEmpty {
                    emptyView
                } else {
                    contactsListView
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import (\(selectedContacts.count))") {
                        importSelectedContacts()
                    }
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
        .onAppear {
            checkAuthorization()
        }
    }
    
    private var noAccessView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Contacts Access Required")
                .font(AppFonts.titleL)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Please enable contacts access in Settings to import contacts.")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppFonts.subtitleM)
            .foregroundColor(AppColors.accentBlue)
            .padding(.top, 8)
        }
        .padding(40)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No Contacts Found")
                .font(AppFonts.titleL)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var contactsListView: some View {
        List {
            ForEach(filteredContacts, id: \.identifier) { contact in
                ImportContactRow(
                    contact: contact,
                    isSelected: selectedContacts.contains(contact.identifier),
                    onTap: {
                        toggleSelection(contact)
                    }
                )
                .listRowBackground(AppColors.backgroundSecondary)
                .listRowSeparatorTint(AppColors.textTertiary.opacity(0.2))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func checkAuthorization() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authorizationStatus = status
        
        switch status {
        case .authorized:
            loadContacts()
        case .notDetermined:
            requestAccess()
        default:
            isLoading = false
        }
    }
    
    private func requestAccess() {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                authorizationStatus = granted ? .authorized : .denied
                if granted {
                    loadContacts()
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    private func loadContacts() {
        DispatchQueue.global(qos: .userInitiated).async {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]
            
            var fetchedContacts: [CNContact] = []
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    fetchedContacts.append(contact)
                }
            } catch {
                print("Error fetching contacts: \(error)")
            }
            
            DispatchQueue.main.async {
                self.contacts = fetchedContacts
                self.isLoading = false
            }
        }
    }
    
    private func toggleSelection(_ contact: CNContact) {
        if selectedContacts.contains(contact.identifier) {
            selectedContacts.remove(contact.identifier)
        } else {
            selectedContacts.insert(contact.identifier)
        }
    }
    
    private func importSelectedContacts() {
        let contactsToImport = contacts.filter { selectedContacts.contains($0.identifier) }
        
        for contact in contactsToImport {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let phone = contact.phoneNumbers.first?.value.stringValue
            let email = contact.emailAddresses.first?.value as String?
            
            secretService.addContact(name: name, phone: phone, email: email, notes: nil)
        }
        
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Import Contact Row

struct ImportContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onTap: () -> Void
    
    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
    
    private var initials: String {
        let parts = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.accentBlue : AppColors.textTertiary.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppColors.accentBlue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.accentBlue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(fullName)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let phone = contact.phoneNumbers.first?.value.stringValue {
                        Text(phone)
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct SecretContactsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SecretContactsView()
        }
    }
}

