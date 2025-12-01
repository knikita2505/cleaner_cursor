import SwiftUI
import Photos

// MARK: - Blurred Photos View
/// Экран для управления размытыми фотографиями

struct BlurredPhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = BlurredPhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.photos.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Blurred photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.photos.isEmpty {
                    Button(viewModel.isSelectionMode ? "Done" : "Select") {
                        withAnimation {
                            viewModel.isSelectionMode.toggle()
                            if !viewModel.isSelectionMode {
                                viewModel.clearSelection()
                            }
                        }
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
        .alert("Delete Photos", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
            }
        } message: {
            Text("Delete \(viewModel.selectedCount) blurred photos? This action cannot be undone.")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                .scaleEffect(1.2)
            
            Text("Analyzing photos for blur...")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No blurred photos")
                .font(AppFonts.titleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text("All your photos are sharp and clear!")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeader
            
            // Photos grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.photos) { photo in
                        BlurredPhotoCell(
                            photo: photo,
                            isSelected: viewModel.isSelected(photo),
                            isSelectionMode: viewModel.isSelectionMode
                        ) {
                            if viewModel.isSelectionMode {
                                viewModel.toggleSelection(photo)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, viewModel.isSelectionMode ? 100 : 20)
            }
            
            // Bottom bar when in selection mode
            if viewModel.isSelectionMode && viewModel.selectedCount > 0 {
                selectionBottomBar
            }
        }
    }
    
    // MARK: - Summary Header
    
    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.photos.count) blurred photos")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(viewModel.formattedTotalSize)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if viewModel.isSelectionMode {
                Button {
                    viewModel.selectAll()
                } label: {
                    Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Selection Bottom Bar
    
    private var selectionBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.selectedCount) selected")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(viewModel.formattedSelectedSize)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Delete")
                    }
                    .font(AppFonts.subtitleM)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.statusError)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.backgroundSecondary)
        }
    }
}

// MARK: - Blurred Photo Cell

struct BlurredPhotoCell: View {
    let photo: PhotoAsset
    let isSelected: Bool
    let isSelectionMode: Bool
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
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 130)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundCard)
                        .frame(height: 130)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                                .scaleEffect(0.6)
                        )
                }
                
                // Blur indicator badge
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.metering.unknown")
                                .font(.system(size: 10))
                            Text("Blurred")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(6)
                        
                        Spacer()
                    }
                }
                
                // Selection indicator
                if isSelectionMode {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isSelected ? AppColors.accentBlue : Color.white.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                    
                    if isSelected {
                        Color.black.opacity(0.2)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        PhotoService.shared.loadThumbnail(for: photo.asset, size: CGSize(width: 200, height: 200)) { image in
            self.thumbnail = image
        }
    }
}

// MARK: - Blurred Photos View Model

@MainActor
class BlurredPhotosViewModel: ObservableObject {
    @Published var photos: [PhotoAsset] = []
    @Published var isLoading = true
    @Published var isSelectionMode = false
    @Published var selectedIds: Set<String> = []
    
    private let photoService = PhotoService.shared
    
    var selectedCount: Int {
        selectedIds.count
    }
    
    var isAllSelected: Bool {
        selectedIds.count == photos.count && !photos.isEmpty
    }
    
    var formattedTotalSize: String {
        let totalSize = photos.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSelectedSize: String {
        let selectedSize = photos.filter { selectedIds.contains($0.id) }.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func load() {
        isLoading = true
        
        Task {
            let blurredPhotos = await Task.detached(priority: .userInitiated) {
                self.photoService.findBlurredPhotos(limit: 500)
            }.value
            
            self.photos = blurredPhotos
            self.isLoading = false
        }
    }
    
    func isSelected(_ photo: PhotoAsset) -> Bool {
        selectedIds.contains(photo.id)
    }
    
    func toggleSelection(_ photo: PhotoAsset) {
        if selectedIds.contains(photo.id) {
            selectedIds.remove(photo.id)
        } else {
            selectedIds.insert(photo.id)
        }
    }
    
    func selectAll() {
        if isAllSelected {
            selectedIds.removeAll()
        } else {
            selectedIds = Set(photos.map { $0.id })
        }
    }
    
    func clearSelection() {
        selectedIds.removeAll()
    }
    
    func deleteSelected() async {
        let assetsToDelete = photos.filter { selectedIds.contains($0.id) }.map { $0.asset }
        
        do {
            try await photoService.deletePhotos(assetsToDelete)
            photos.removeAll { selectedIds.contains($0.id) }
            selectedIds.removeAll()
            isSelectionMode = false
        } catch {
            print("Error deleting photos: \(error)")
        }
    }
}

