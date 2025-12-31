import SwiftUI
import Photos
import AVKit

// MARK: - Short Videos View

struct ShortVideosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ShortVideosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var selectedVideo: VideoAsset? = nil
    @State private var showVideoDetail = false
    @State private var sortOption: VideoSortOption = .recent
    @State private var showSortPicker = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
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
            
            // Video Detail Sheet
            if showVideoDetail, let video = selectedVideo {
                ShortVideoDetailSheet(
                    video: video,
                    isPresented: $showVideoDetail,
                    onDelete: {
                        Task {
                            await viewModel.deleteVideo(video)
                        }
                    }
                )
            }
            
            // Processing overlay
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .navigationTitle("Short Videos")
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
            Text("Delete \(viewModel.selectedCount) short videos? This action cannot be undone.")
        }
        .confirmationDialog("Sort by", isPresented: $showSortPicker, titleVisibility: .visible) {
            ForEach(VideoSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    sortOption = option
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                .scaleEffect(1.2)
            
            Text("Loading short videos...")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No short videos")
                .font(AppFonts.titleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Videos under 10 seconds will appear here")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Category hint
            categoryHint
            
            // Summary header
            summaryHeader
            
            // Videos grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(sortedVideos) { video in
                        ShortVideoCell(
                            video: video,
                            isSelected: viewModel.isSelected(video),
                            isSelectionMode: viewModel.isSelectionMode
                        ) {
                            if viewModel.isSelectionMode {
                                viewModel.toggleSelection(video)
                            } else {
                                selectedVideo = video
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showVideoDetail = true
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, viewModel.isSelectionMode ? 100 : 20)
            }
            
            // Bottom bar when in selection mode
            if viewModel.isSelectionMode && viewModel.selectedCount > 0 {
                selectionBottomBar
            }
        }
    }
    
    // MARK: - Category Hint
    
    private var categoryHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppColors.statusWarning)
            
            Text("Short videos (under 10 seconds) often include accidental recordings, failed takes, or unnecessary clips that take up storage.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.statusWarning.opacity(0.1))
    }
    
    // MARK: - Summary Header
    
    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sortedVideos.count) short videos")
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
            
            // Sort button
            Button {
                showSortPicker = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.backgroundSecondary)
    }
    
    private var sortedVideos: [VideoAsset] {
        switch sortOption {
        case .recent:
            return viewModel.videos.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            return viewModel.videos.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        case .largest:
            return viewModel.videos.sorted { $0.fileSize > $1.fileSize }
        }
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
                    .frame(width: 100)
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
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.5)
                
                Text("Deleting...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Short Video Detail Sheet

struct ShortVideoDetailSheet: View {
    let video: VideoAsset
    @Binding var isPresented: Bool
    var onDelete: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var showPlayer = false
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9 * opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    closeSheet()
                }
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    
                    // Video Preview
                    ZStack {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                                .cornerRadius(16)
                        } else {
                            Rectangle()
                                .fill(AppColors.backgroundCard)
                                .frame(height: 280)
                                .cornerRadius(16)
                        }
                        
                        // Play button
                        Button {
                            showPlayer = true
                        } label: {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .offset(x: 3)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Video Info
                    HStack(spacing: 20) {
                        infoItem(icon: "clock", value: video.formattedDuration)
                        infoItem(icon: "doc", value: video.formattedSize)
                        infoItem(icon: "calendar", value: video.formattedDate)
                    }
                    .padding(.vertical, 20)
                    
                    Divider()
                        .background(AppColors.borderSecondary)
                        .padding(.horizontal, 20)
                    
                    // Delete Button
                    Button {
                        onDelete()
                        closeSheet()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delete")
                                    .font(AppFonts.subtitleL)
                                    .foregroundColor(.white)
                                
                                Text("Save \(video.formattedSize) by deleting video")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "trash")
                                .foregroundColor(AppColors.statusError)
                        }
                        .padding(16)
                        .background(AppColors.statusError.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .padding(20)
                }
                .background(AppColors.backgroundSecondary)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                offset = value.translation.height
                                opacity = 1 - Double(value.translation.height / 400)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 || value.predictedEndTranslation.height > 300 {
                                closeSheetWithSwipe()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = 0
                                    opacity = 1
                                }
                            }
                        }
                )
            }
        }
        .transition(.opacity)
        .onAppear {
            loadThumbnail()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            ShortVideoPlayerView(asset: video.asset)
        }
    }
    
    private func infoItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textTertiary)
            
            Text(value)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        VideoService.shared.loadThumbnail(for: video.asset, size: CGSize(width: 600, height: 400)) { image in
            self.thumbnail = image
        }
    }
    
    private func closeSheet() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
    
    private func closeSheetWithSwipe() {
        withAnimation(.easeOut(duration: 0.25)) {
            offset = UIScreen.main.bounds.height
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Short Video Player View

struct ShortVideoPlayerView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                DispatchQueue.main.async {
                    self.player = AVPlayer(url: urlAsset.url)
                    self.player?.play()
                }
            } else if let composition = avAsset as? AVComposition {
                let playerItem = AVPlayerItem(asset: composition)
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: playerItem)
                    self.player?.play()
                }
            }
        }
    }
}

// MARK: - Short Video Cell

struct ShortVideoCell: View {
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
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundCard)
                        .frame(height: 180)
                }
                
                // Top row: Favorite badge
                VStack {
                    HStack {
                        Spacer()
                        if video.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(5)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Bottom info: Size and Duration
                    HStack {
                        // Size badge
                        Text(video.formattedSize)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // Duration badge
                        Text(video.formattedDuration)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .padding(8)
                }
                
                // Selection indicator
                if isSelectionMode {
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? AppColors.accentBlue : Color.white.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(10)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    if isSelected {
                        Color.black.opacity(0.2)
                    }
                }
            }
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        VideoService.shared.loadThumbnail(for: video.asset, size: CGSize(width: 400, height: 400)) { image in
            self.thumbnail = image
        }
    }
}

// MARK: - Short Videos View Model

// MARK: - Short Videos View Model

@MainActor
class ShortVideosViewModel: ObservableObject {
    @Published var videos: [VideoAsset] = []
    @Published var isLoading = true
    @Published var isSelectionMode = false
    @Published var selectedIds: Set<String> = []
    @Published var isProcessing = false
    
    private let videoService = VideoService.shared
    
    var selectedCount: Int {
        selectedIds.count
    }
    
    var isAllSelected: Bool {
        let nonFavoriteCount = videos.filter { !$0.isFavorite }.count
        return selectedIds.count == nonFavoriteCount && nonFavoriteCount > 0
    }
    
    var formattedTotalSize: String {
        let totalSize = videos.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedSelectedSize: String {
        let selectedSize = videos.filter { selectedIds.contains($0.id) }.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    func load() {
        isLoading = true
        
        Task {
            let videoService = VideoService.shared
            let result = await Task.detached(priority: .userInitiated) {
                let fetchResult = videoService.fetchShortVideos()
                var videos: [VideoAsset] = []
                fetchResult.enumerateObjects { asset, _, _ in
                    videos.append(VideoAsset(asset: asset))
                }
                return videos.sorted { $0.duration < $1.duration }
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
            // Select all non-favorite videos
            selectedIds = Set(videos.filter { !$0.isFavorite }.map { $0.id })
        }
    }
    
    func clearSelection() {
        selectedIds.removeAll()
    }
    
    func deleteVideo(_ video: VideoAsset) async {
        isProcessing = true
        
        do {
            try await videoService.deleteVideos([video.asset])
            withAnimation {
                videos.removeAll { $0.id == video.id }
            }
            HapticManager.success()
        } catch {
            print("Error deleting video: \(error)")
            HapticManager.error()
        }
        
        isProcessing = false
    }
    
    func deleteSelected() async {
        let assetsToDelete = videos.filter { selectedIds.contains($0.id) }.map { $0.asset }
        
        isProcessing = true
        
        do {
            try await videoService.deleteVideos(assetsToDelete)
            withAnimation {
                videos.removeAll { selectedIds.contains($0.id) }
            }
            selectedIds.removeAll()
            isSelectionMode = false
            HapticManager.success()
        } catch {
            print("Error deleting videos: \(error)")
            HapticManager.error()
        }
        
        isProcessing = false
    }
}
