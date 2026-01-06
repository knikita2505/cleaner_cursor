import SwiftUI
import PhotosUI
import Photos
import AVKit

// MARK: - Secret Album View
/// Галерея скрытых фото и видео согласно secret_album.md

struct SecretAlbumView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    
    @State private var selectedItems: Set<String> = []
    @State private var isSelectionMode = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var selectedMediaItem: SecretMediaItem?
    @State private var showFullscreen = false
    @State private var isImporting = false
    @State private var importProgress: String = ""
    @State private var deleteOriginals = true
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    private var allMedia: [SecretMediaItem] {
        secretService.secretPhotos + secretService.secretVideos
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if allMedia.isEmpty && !isImporting {
                    emptyStateView
                } else {
                    gridView
                }
            }
            
            // Import overlay
            if isImporting {
                importingOverlay
            }
        }
        .navigationTitle("Secret Album")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !allMedia.isEmpty {
                    Button(isSelectionMode ? "Done" : "Select") {
                        withAnimation {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedItems.removeAll()
                            }
                        }
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(
                onSelect: { assets in
                    importPhotos(assets)
                },
                deleteOriginals: $deleteOriginals
            )
        }
        .sheet(item: $selectedMediaItem) { item in
            MediaDetailView(item: item)
        }
        .alert("Delete Selected?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedItems()
            }
        } message: {
            Text("These items will be permanently deleted from Secret Album.")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accentBlue)
            }
            
            VStack(spacing: 8) {
                Text("No Hidden Media")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Add photos and videos from your\nlibrary to keep them private")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showPhotoPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add from Photos")
                        .font(AppFonts.subtitleM)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppGradients.ctaGradient)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding(AppSpacing.screenPadding)
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(allMedia) { item in
                    MediaGridCell(
                        item: item,
                        isSelected: selectedItems.contains(item.id),
                        isSelectionMode: isSelectionMode,
                        onTap: {
                            handleItemTap(item)
                        }
                    )
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.textTertiary.opacity(0.2))
            
            if isSelectionMode && !selectedItems.isEmpty {
                // Selection mode actions
                VStack(spacing: 8) {
                    Text("\(selectedItems.count) selected")
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                            Text("Delete Selected")
                                .font(AppFonts.subtitleM)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.statusError)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, 12)
            } else {
                // Add button
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add from Photos")
                            .font(AppFonts.subtitleM)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppGradients.ctaGradient)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, 12)
            }
        }
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Importing Overlay
    
    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.accentBlue)
                
                Text("Importing...")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                if !importProgress.isEmpty {
                    Text(importProgress)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(32)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Actions
    
    private func handleItemTap(_ item: SecretMediaItem) {
        if isSelectionMode {
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
        } else {
            selectedMediaItem = item
        }
    }
    
    private func importPhotos(_ assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        
        isImporting = true
        importProgress = "0 / \(assets.count)"
        
        Task {
            do {
                let count = try await secretService.addPhotosFromLibrary(assets, deleteOriginals: deleteOriginals)
                importProgress = "\(count) / \(assets.count)"
                
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                await MainActor.run {
                    isImporting = false
                    importProgress = ""
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    importProgress = ""
                    HapticManager.error()
                }
            }
        }
    }
    
    private func deleteSelectedItems() {
        let itemsToDelete = allMedia.filter { selectedItems.contains($0.id) }
        
        do {
            try secretService.deleteSecretItems(itemsToDelete)
            selectedItems.removeAll()
            isSelectionMode = false
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
    }
    
}

// MARK: - Media Grid Cell

struct MediaGridCell: View {
    let item: SecretMediaItem
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geo in
                ZStack {
                    // Thumbnail
                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.width)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(AppColors.backgroundSecondary)
                            .frame(width: geo.size.width, height: geo.size.width)
                            .overlay {
                                ProgressView()
                                    .tint(AppColors.textTertiary)
                            }
                    }
                    
                    // Video indicator
                    if item.type == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text(item.formattedSize)
                                    .font(.system(size: 10, weight: .medium))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(6)
                            .background(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
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
                    }
                }
                .contentShape(Rectangle())
            }
            .aspectRatio(1, contentMode: .fill)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let currentItem = item
        Task {
            let image: UIImage?
            
            if currentItem.type == .photo {
                image = SecretSpaceService.shared.loadImage(for: currentItem)
            } else {
                image = SecretSpaceService.shared.loadVideoThumbnail(for: currentItem)
            }
            
            self.thumbnail = image
        }
    }
}

// MARK: - Media Detail View

struct MediaDetailView: View {
    let item: SecretMediaItem
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Content
            if item.type == .photo {
                PhotoDetailContent(item: item)
            } else {
                VideoDetailContent(item: item)
            }
            
            // Overlay controls
            if showControls {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.9), .black.opacity(0.3))
                        }
                        
                        Spacer()
                        
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.9), .black.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if item.type == .video {
                ShareSheet(items: [item.fileURL])
            } else if let image = SecretSpaceService.shared.loadImage(for: item) {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Photo Detail Content

struct PhotoDetailContent: View {
    let item: SecretMediaItem
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let currentItem = item
        Task {
            let loaded = SecretSpaceService.shared.loadImage(for: currentItem)
            image = loaded
        }
    }
}

// MARK: - Video Detail Content

struct VideoDetailContent: View {
    let item: SecretMediaItem
    @State private var player: AVPlayer?
    
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        let videoPlayer = AVPlayer(url: item.fileURL)
        player = videoPlayer
        videoPlayer.play()
    }
}

// MARK: - Photo Picker View

struct PhotoPickerView: View {
    let onSelect: ([PHAsset]) -> Void
    @Binding var deleteOriginals: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAssets: [PHAsset] = []
    @State private var allAssets: [PHAsset] = []
    @State private var isLoading = true
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(AppColors.accentBlue)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(allAssets, id: \.localIdentifier) { asset in
                                    AssetPickerCell(
                                        asset: asset,
                                        isSelected: selectedAssets.contains(where: { $0.localIdentifier == asset.localIdentifier }),
                                        onTap: {
                                            toggleSelection(asset)
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        
                        // Delete originals toggle
                        VStack(spacing: 0) {
                            Divider()
                                .background(AppColors.textTertiary.opacity(0.2))
                            
                            Toggle(isOn: $deleteOriginals) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete originals from Photos")
                                        .font(AppFonts.bodyL)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text("Remove photos from your library after hiding")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            .tint(AppColors.accentBlue)
                            .padding(AppSpacing.containerPadding)
                        }
                        .background(AppColors.backgroundSecondary)
                    }
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedAssets.count))") {
                        onSelect(selectedAssets)
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(selectedAssets.isEmpty)
                }
            }
        }
        .onAppear {
            loadAssets()
        }
    }
    
    private func loadAssets() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let photosResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let videosResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            
            var assets: [PHAsset] = []
            
            photosResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            videosResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            // Сортируем по дате
            assets.sort { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
            
            DispatchQueue.main.async {
                self.allAssets = assets
                self.isLoading = false
            }
        }
    }
    
    private func toggleSelection(_ asset: PHAsset) {
        if let index = selectedAssets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
            selectedAssets.remove(at: index)
        } else {
            selectedAssets.append(asset)
        }
    }
}

// MARK: - Asset Picker Cell

struct AssetPickerCell: View {
    let asset: PHAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geo in
                ZStack {
                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.width)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(AppColors.backgroundSecondary)
                    }
                    
                    // Video indicator
                    if asset.mediaType == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(6)
                            .background(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    
                    // Selection indicator
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
                }
                .contentShape(Rectangle())
            }
            .aspectRatio(1, contentMode: .fill)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct SecretAlbumView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SecretAlbumView()
        }
    }
}

