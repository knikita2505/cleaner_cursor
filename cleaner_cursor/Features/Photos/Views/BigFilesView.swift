import SwiftUI
import Photos

// MARK: - Big Files View

struct BigFilesView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = BigFilesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.files.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Header with filters
                    filterBar
                    
                    // Files List
                    filesList
                    
                    // Bottom Action Bar
                    if viewModel.selectedCount > 0 {
                        bottomActionBar
                    }
                }
            }
            
            // Loading
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Big Files")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Files?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
            }
        } message: {
            Text("Delete \(viewModel.selectedCount) files? They will be removed permanently.")
        }
        .task {
            await viewModel.loadFiles()
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        VStack(spacing: 12) {
            // Type Filter
            HStack(spacing: 8) {
                ForEach(BigFilesViewModel.FileTypeFilter.allCases, id: \.rawValue) { filter in
                    Button {
                        viewModel.typeFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(AppFonts.caption)
                            .foregroundColor(viewModel.typeFilter == filter ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.typeFilter == filter
                                    ? AppColors.accentBlue
                                    : AppColors.backgroundCard
                            )
                            .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
            
            // Sort & Info
            HStack {
                Text("\(viewModel.files.count) files • \(viewModel.formattedTotalSize)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Menu {
                    Button("Size (Largest)") { viewModel.sortBy = .sizeLargest }
                    Button("Date (Newest)") { viewModel.sortBy = .dateNewest }
                    Button("Date (Oldest)") { viewModel.sortBy = .dateOldest }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort")
                        Image(systemName: "chevron.down")
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .padding(AppSpacing.screenPadding)
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Files List
    
    private var filesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.files.indices, id: \.self) { index in
                    BigFileRow(
                        file: viewModel.files[index],
                        isSelected: viewModel.selectedIndices.contains(index),
                        onTap: { viewModel.toggleSelection(at: index) }
                    )
                }
            }
            .padding(AppSpacing.screenPadding)
            .padding(.bottom, viewModel.selectedCount > 0 ? 100 : 20)
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected: \(viewModel.selectedCount)")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Free up: \(viewModel.formattedSelectedSize)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Delete selected")
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
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "doc.fill",
            iconColor: AppColors.statusError,
            title: "No Large Files",
            description: "You don't have any files larger than \(viewModel.minSizeMB) MB.",
            buttonTitle: "Change Filter"
        ) {
            // TODO: Show size filter picker
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.3)
                
                Text("Finding large files...")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(32)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Big File Row

struct BigFileRow: View {
    let file: BigFileItem
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Thumbnail
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .cornerRadius(10)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(AppColors.backgroundCard)
                            .frame(width: 64, height: 64)
                            .cornerRadius(10)
                    }
                    
                    // Video indicator
                    if file.isVideo {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.typeLabel)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(file.formattedDate)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    HStack(spacing: 8) {
                        Text("Size: \(file.formattedSize)")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if file.isVideo, let duration = file.formattedDuration {
                            Text("• \(duration)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    
                    if file.isRecommended {
                        Text("Recommended for deletion")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.statusWarning)
                    }
                }
                
                Spacer()
                
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.accentBlue : AppColors.borderSecondary, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.accentBlue)
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? AppColors.accentBlue.opacity(0.1) : AppColors.backgroundCard)
            .cornerRadius(AppSpacing.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                    .stroke(isSelected ? AppColors.accentBlue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        if file.isVideo {
            VideoService.shared.loadThumbnail(
                for: file.asset,
                size: CGSize(width: 200, height: 200)
            ) { image in
                thumbnail = image
            }
        } else {
            PhotoService.shared.loadThumbnail(
                for: file.asset,
                size: CGSize(width: 200, height: 200)
            ) { image in
                thumbnail = image
            }
        }
    }
}

// MARK: - Big Files ViewModel

@MainActor
final class BigFilesViewModel: ObservableObject {
    
    @Published var files: [BigFileItem] = []
    @Published var selectedIndices: Set<Int> = []
    @Published var isLoading: Bool = true
    @Published var typeFilter: FileTypeFilter = .all {
        didSet { applyFilters() }
    }
    @Published var sortBy: SortOption = .sizeLargest {
        didSet { applyFilters() }
    }
    
    let minSizeMB: Int = 20
    
    enum FileTypeFilter: String, CaseIterable {
        case all = "All"
        case photos = "Photos"
        case videos = "Videos"
    }
    
    enum SortOption {
        case sizeLargest, dateNewest, dateOldest
    }
    
    private var allFiles: [BigFileItem] = []
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    
    var selectedCount: Int { selectedIndices.count }
    
    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        selectedIndices.reduce(Int64(0)) { result, index in
            guard index < files.count else { return result }
            return result + files[index].size
        }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func loadFiles() async {
        isLoading = true
        
        let minSize = Int64(minSizeMB * 1_000_000)
        var items: [BigFileItem] = []
        
        // Load big photos
        let bigPhotos = photoService.fetchBigPhotos(minSize: minSize)
        for photo in bigPhotos {
            items.append(BigFileItem(
                asset: photo.asset,
                size: photo.fileSize,
                date: photo.creationDate,
                isVideo: false,
                duration: nil
            ))
        }
        
        // Load big videos
        let bigVideos = videoService.fetchLargeVideos(minSize: minSize)
        for video in bigVideos {
            items.append(BigFileItem(
                asset: video.asset,
                size: video.fileSize,
                date: video.creationDate,
                isVideo: true,
                duration: video.duration
            ))
        }
        
        allFiles = items
        applyFilters()
        
        isLoading = false
    }
    
    private func applyFilters() {
        // Filter by type
        var filtered = allFiles
        switch typeFilter {
        case .all:
            break
        case .photos:
            filtered = allFiles.filter { !$0.isVideo }
        case .videos:
            filtered = allFiles.filter { $0.isVideo }
        }
        
        // Sort
        switch sortBy {
        case .sizeLargest:
            filtered.sort { $0.size > $1.size }
        case .dateNewest:
            filtered.sort { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        case .dateOldest:
            filtered.sort { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        }
        
        files = filtered
        selectedIndices.removeAll()
    }
    
    func toggleSelection(at index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    func deleteSelected() async {
        let assetsToDelete = selectedIndices.compactMap { index -> PHAsset? in
            guard index < files.count else { return nil }
            return files[index].asset
        }
        
        do {
            // Calculate bytes freed
            let bytesFreed = selectedIndices.reduce(Int64(0)) { total, index in
                guard index < files.count else { return total }
                return total + files[index].size
            }
            
            try await photoService.deletePhotos(assetsToDelete)
            
            // Record to history
            CleaningHistoryService.shared.recordCleaning(
                type: .bigFiles,
                itemsCount: assetsToDelete.count,
                bytesFreed: bytesFreed
            )
            
            // Remove deleted items
            files = files.enumerated()
                .filter { !selectedIndices.contains($0.offset) }
                .map { $0.element }
            
            // Also remove from allFiles
            let deletedIds = Set(assetsToDelete.map { $0.localIdentifier })
            allFiles = allFiles.filter { !deletedIds.contains($0.asset.localIdentifier) }
            
            selectedIndices.removeAll()
            
            SubscriptionService.shared.recordCleaning(count: assetsToDelete.count)
            
        } catch {
            print("Failed to delete files: \(error)")
        }
    }
}

// MARK: - Big File Item Model

struct BigFileItem: Identifiable {
    let id: String
    let asset: PHAsset
    let size: Int64
    let date: Date?
    let isVideo: Bool
    let duration: TimeInterval?
    
    init(asset: PHAsset, size: Int64, date: Date?, isVideo: Bool, duration: TimeInterval?) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.size = size
        self.date = date
        self.isVideo = isVideo
        self.duration = duration
    }
    
    var typeLabel: String {
        isVideo ? "Video" : "Photo"
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        guard let date = date else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var isRecommended: Bool {
        size > 100_000_000 // > 100MB
    }
}

// MARK: - Preview

struct BigFilesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BigFilesView()
        }
    }
}

