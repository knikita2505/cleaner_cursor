import SwiftUI
import Photos

// MARK: - Screenshots View
/// Экран для работы со скриншотами

struct ScreenshotsView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ScreenshotsViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var sortOption: PhotoSortOption = .recent
    @State private var showSortPicker: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    private var sortedScreenshots: [PhotoAsset] {
        switch sortOption {
        case .recent:
            return viewModel.screenshots.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            return viewModel.screenshots.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        case .largest:
            return viewModel.screenshots.sorted { $0.fileSize > $1.fileSize }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.screenshots.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Summary Header with sort
                    summaryHeader
                    
                    // Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(sortedScreenshots) { screenshot in
                                if let index = viewModel.screenshots.firstIndex(where: { $0.id == screenshot.id }) {
                                    ScreenshotCell(
                                        asset: screenshot,
                                        isSelected: viewModel.selectedIndices.contains(index),
                                        onTap: {
                                            viewModel.toggleSelection(at: index)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom Action Bar
                    if viewModel.isSelectionMode && !viewModel.selectedIndices.isEmpty {
                        bottomActionBar
                    }
                }
            }
            
            // Loading
            if viewModel.isLoading {
                LoadingStateView(title: "Loading screenshots...")
            }
            
            // Deleting
            if viewModel.isDeleting {
                deletingOverlay
            }
        }
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Screenshots?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
            }
        } message: {
            Text("Delete \(viewModel.selectedIndices.count) screenshots? This cannot be undone.")
        }
        .confirmationDialog("Sort by", isPresented: $showSortPicker, titleVisibility: .visible) {
            ForEach(PhotoSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    sortOption = option
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            Task {
                await viewModel.loadScreenshots()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "camera.viewfinder",
            iconColor: AppColors.statusSuccess,
            title: "No Screenshots",
            description: "You don't have any screenshots to clean.",
            buttonTitle: "Go Back"
        ) {
            dismiss()
        }
    }
    
    // MARK: - Selection Header
    
    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sortedScreenshots.count) screenshots")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(viewModel.formattedTotalSize)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if viewModel.isSelectionMode {
                Button {
                    viewModel.selectAllNonFavorites()
                } label: {
                    Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accentBlue)
                }
            }
            
            // Sort button
            Button {
                showSortPicker = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected: \(viewModel.selectedIndices.count)")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Free up: \(viewModel.formattedSelectedSize)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(AppFonts.buttonSecondary)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppColors.statusError)
                    .cornerRadius(AppSpacing.buttonRadius)
                }
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.backgroundSecondary)
        }
    }
    
    // MARK: - Deleting Overlay
    
    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Deleting...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Screenshot Cell

struct ScreenshotCell: View {
    let asset: PhotoAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Thumbnail
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundCard)
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                                .scaleEffect(0.8)
                        )
                }
                
                // Top badges
                VStack {
                    HStack {
                        // Selection indicator
                        ZStack {
                            Circle()
                                .fill(isSelected ? AppColors.accentBlue : Color.black.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        
                        Spacer()
                        
                        // Favorite badge
                        if asset.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(6)
                    
                    Spacer()
                }
                
                // Selection overlay
                if isSelected {
                    Rectangle()
                        .fill(AppColors.accentBlue.opacity(0.2))
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        let size = CGSize(width: 200, height: 200)
        PhotoService.shared.loadThumbnail(for: asset.asset, size: size) { image in
            self.thumbnail = image
        }
    }
}

// MARK: - Screenshots ViewModel

@MainActor
class ScreenshotsViewModel: ObservableObject {
    
    @Published var screenshots: [PhotoAsset] = []
    @Published var selectedIndices: Set<Int> = []
    @Published var isLoading: Bool = true
    @Published var isDeleting: Bool = false
    @Published var isSelectionMode: Bool = true
    
    private let photoService = PhotoService.shared
    
    var isAllSelected: Bool {
        let nonFavoriteCount = screenshots.filter { !$0.isFavorite }.count
        return selectedIndices.count == nonFavoriteCount && nonFavoriteCount > 0
    }
    
    var totalSize: Int64 {
        screenshots.reduce(Int64(0)) { $0 + $1.fileSize }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        selectedIndices.reduce(0) { result, index in
            guard index < screenshots.count else { return result }
            return result + screenshots[index].fileSize
        }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func loadScreenshots() async {
        isLoading = true
        screenshots = photoService.fetchScreenshotsAsAssets()
        isLoading = false
    }
    
    func toggleSelection(at index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    func selectAll() {
        if isAllSelected {
            selectedIndices.removeAll()
        } else {
            selectedIndices = Set(0..<screenshots.count)
        }
    }
    
    /// Select all non-favorite screenshots
    func selectAllNonFavorites() {
        if isAllSelected {
            selectedIndices.removeAll()
        } else {
            selectedIndices = Set(screenshots.enumerated().compactMap { index, asset in
                asset.isFavorite ? nil : index
            })
        }
    }
    
    func deleteSelected() async {
        guard !selectedIndices.isEmpty else { return }
        
        isDeleting = true
        
        let assetsToDelete = selectedIndices.compactMap { index -> PhotoAsset? in
            guard index < screenshots.count else { return nil }
            return screenshots[index]
        }
        
        do {
            try await photoService.deletePhotoAssets(assetsToDelete)
            
            // Remove deleted items
            screenshots = screenshots.enumerated().compactMap { index, asset in
                selectedIndices.contains(index) ? nil : asset
            }
            
            selectedIndices.removeAll()
            
            HapticManager.success()
        } catch {
            print("Delete failed: \(error)")
            HapticManager.error()
        }
        
        isDeleting = false
    }
}

// MARK: - Preview

struct ScreenshotsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScreenshotsView()
        }
    }
}

