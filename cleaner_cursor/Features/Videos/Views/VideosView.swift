import SwiftUI
import Photos

// MARK: - Videos View
/// Экран для управления всеми видео

struct VideosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = VideosViewModel()
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
            } else if viewModel.videos.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.videos.isEmpty {
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
        .alert("Delete Videos", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
            }
        } message: {
            Text("Delete \(viewModel.selectedCount) videos? This action cannot be undone.")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                .scaleEffect(1.2)
            
            Text("Loading videos...")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No videos")
                .font(AppFonts.titleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Your videos will appear here")
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
            
            // Videos grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.videos) { video in
                        VideoCell(
                            video: video,
                            isSelected: viewModel.isSelected(video),
                            isSelectionMode: viewModel.isSelectionMode
                        ) {
                            if viewModel.isSelectionMode {
                                viewModel.toggleSelection(video)
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
                Text("\(viewModel.videos.count) videos")
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

// MARK: - Video Cell

struct VideoCell: View {
    let video: VideoAsset
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
                }
                
                // Duration badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(video.formattedDuration)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }
                
                // Selection indicator
                if isSelectionMode {
                    VStack {
                        HStack {
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
                            
                            Spacer()
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
        VideoService.shared.loadThumbnail(for: video.asset, size: CGSize(width: 200, height: 200)) { image in
            self.thumbnail = image
        }
    }
}

// MARK: - Videos View Model

@MainActor
class VideosViewModel: ObservableObject {
    @Published var videos: [VideoAsset] = []
    @Published var isLoading = true
    @Published var isSelectionMode = false
    @Published var selectedIds: Set<String> = []
    
    private let videoService = VideoService.shared
    
    var selectedCount: Int {
        selectedIds.count
    }
    
    var isAllSelected: Bool {
        selectedIds.count == videos.count && !videos.isEmpty
    }
    
    var formattedTotalSize: String {
        let totalSize = videos.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSelectedSize: String {
        let selectedSize = videos.filter { selectedIds.contains($0.id) }.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    @MainActor
    func load() {
        isLoading = true
        
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                let fetchResult = VideoService.shared.fetchAllVideos()
                var videos: [VideoAsset] = []
                fetchResult.enumerateObjects { asset, _, _ in
                    videos.append(VideoAsset(asset: asset))
                }
                return videos
            }.value
            
            self.videos = result
            self.isLoading = false
        }
    }
    
    func isSelected(_ video: VideoAsset) -> Bool {
        selectedIds.contains(video.id)
    }
    
    func toggleSelection(_ video: VideoAsset) {
        if selectedIds.contains(video.id) {
            selectedIds.remove(video.id)
        } else {
            selectedIds.insert(video.id)
        }
    }
    
    func selectAll() {
        if isAllSelected {
            selectedIds.removeAll()
        } else {
            selectedIds = Set(videos.map { $0.id })
        }
    }
    
    func clearSelection() {
        selectedIds.removeAll()
    }
    
    func deleteSelected() async {
        let assetsToDelete = videos.filter { selectedIds.contains($0.id) }.map { $0.asset }
        
        do {
            try await videoService.deleteVideos(assetsToDelete)
            videos.removeAll { selectedIds.contains($0.id) }
            selectedIds.removeAll()
            isSelectionMode = false
        } catch {
            print("Error deleting videos: \(error)")
        }
    }
}

