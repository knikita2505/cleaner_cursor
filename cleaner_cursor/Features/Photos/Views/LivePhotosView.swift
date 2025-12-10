import SwiftUI
import Photos
import PhotosUI

// MARK: - Live Photos View

struct LivePhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = LivePhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var expandedIndex: Int? = nil
    
    @State private var showPreview: Bool = false
    @State private var previewAsset: PHAsset? = nil
    @State private var sortOption: PhotoSortOption = .recent
    @State private var showSortPicker: Bool = false
    
    private var sortedLivePhotos: [LivePhotoAsset] {
        switch sortOption {
        case .recent:
            return viewModel.livePhotos.sorted { ($0.asset.creationDate ?? .distantPast) > ($1.asset.creationDate ?? .distantPast) }
        case .oldest:
            return viewModel.livePhotos.sorted { ($0.asset.creationDate ?? .distantPast) < ($1.asset.creationDate ?? .distantPast) }
        case .largest:
            return viewModel.livePhotos.sorted { $0.fileSize > $1.fileSize }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.livePhotos.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Summary Card
                    summaryCard
                    
                    // Live Photos List
                    livePhotosList
                    
                    // Bottom Action Bar
                    if viewModel.isMultiSelectMode {
                        multiSelectBottomBar
                    } else {
                        bottomActionBar
                    }
                }
            }
            
            // Live Photo Preview
            if showPreview, let asset = previewAsset {
                livePhotoPreview(asset: asset)
            }
            
            // Loading/Processing Overlay
            if viewModel.isLoading || viewModel.isProcessing {
                processingOverlay
            }
        }
        .navigationTitle("Live Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isMultiSelectMode {
                    Button("Done") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.exitMultiSelectMode()
                        }
                    }
                    .foregroundColor(AppColors.accentBlue)
                } else {
                    Menu {
                        Button {
                            viewModel.setAllToKeep()
                        } label: {
                            Label("Keep All", systemImage: "checkmark.circle")
                        }
                        
                        Button {
                            viewModel.setAllToConvert()
                        } label: {
                            Label("Convert All", systemImage: "photo")
                        }
                        
                        Button {
                            viewModel.setAllToDelete()
                        } label: {
                            Label("Delete All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
            }
        }
        .task {
            await viewModel.loadLivePhotos()
        }
        .confirmationDialog("Sort by", isPresented: $showSortPicker, titleVisibility: .visible) {
            ForEach(PhotoSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    sortOption = option
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Live Photo Preview
    
    @State private var previewOffset: CGFloat = 0
    @State private var previewOpacity: Double = 1
    
    private func livePhotoPreview(asset: PHAsset) -> some View {
        ZStack {
            // Dimmed background - тап закрывает
            Color.black.opacity(0.9 * previewOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    closePreview()
                }
            
            // Live Photo View with drag gesture
            VStack {
                Spacer()
                
                LivePhotoPlayerView(asset: asset)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.65)
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                    .offset(y: previewOffset)
                    .scaleEffect(1 - (previewOffset / 1000))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Только свайп вниз
                                if value.translation.height > 0 {
                                    previewOffset = value.translation.height
                                    previewOpacity = 1 - Double(value.translation.height / 400)
                                }
                            }
                            .onEnded { value in
                                // Если свайп достаточно сильный - закрываем
                                // predictedEndTranslation показывает куда бы улетел элемент
                                if value.translation.height > 100 || value.predictedEndTranslation.height > 300 {
                                    closePreviewWithSwipe()
                                } else {
                                    // Возвращаем на место
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        previewOffset = 0
                                        previewOpacity = 1
                                    }
                                }
                            }
                    )
                
                Spacer()
            }
        }
        .transition(.opacity)
        .onAppear {
            previewOffset = 0
            previewOpacity = 1
        }
    }
    
    private func closePreview() {
        withAnimation(.easeOut(duration: 0.2)) {
            showPreview = false
            previewAsset = nil
            previewOffset = 0
            previewOpacity = 1
        }
    }
    
    private func closePreviewWithSwipe() {
        withAnimation(.easeOut(duration: 0.25)) {
            previewOffset = UIScreen.main.bounds.height
            previewOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showPreview = false
            previewAsset = nil
            previewOffset = 0
            previewOpacity = 1
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You can save up to")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(viewModel.formattedTotalSavings)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(sortedLivePhotos.count)")
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Live Photos")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // Sort button
                Button {
                    showSortPicker = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accentBlue)
                }
                .padding(.leading, 8)
            }
            
            // Action breakdown
            HStack(spacing: 16) {
                actionBadge(
                    count: viewModel.keepCount,
                    label: "Keep",
                    color: AppColors.statusSuccess
                )
                
                actionBadge(
                    count: viewModel.convertCount,
                    label: "Convert",
                    color: AppColors.accentBlue
                )
                
                actionBadge(
                    count: viewModel.deleteCount,
                    label: "Delete",
                    color: AppColors.statusError
                )
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
    }
    
    private func actionBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(AppFonts.subtitleL)
                .foregroundColor(color)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Live Photos List
    
    private var livePhotosList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedLivePhotos) { livePhoto in
                    let index = viewModel.livePhotos.firstIndex(where: { $0.id == livePhoto.id }) ?? 0
                    LivePhotoCard(
                        livePhoto: Binding(
                            get: { viewModel.livePhotos[index] },
                            set: { viewModel.livePhotos[index] = $0 }
                        ),
                        isExpanded: expandedIndex == index,
                        isMultiSelectMode: viewModel.isMultiSelectMode,
                        isSelected: viewModel.selectedIndices.contains(index),
                        onThumbnailTap: {
                            previewAsset = viewModel.livePhotos[index].asset
                            withAnimation(.easeOut(duration: 0.25)) {
                                showPreview = true
                            }
                        },
                        onCardTap: {
                            if viewModel.isMultiSelectMode {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleSelection(index)
                                }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    if expandedIndex == index {
                                        expandedIndex = nil
                                    } else {
                                        expandedIndex = index
                                    }
                                }
                            }
                        },
                        onLongPress: {
                            if !viewModel.isMultiSelectMode {
                                HapticManager.impact(.medium)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    expandedIndex = nil
                                    viewModel.enterMultiSelectMode(startingWith: index)
                                }
                            }
                        },
                        onActionSelected: { action in
                            viewModel.livePhotos[index].action = action
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedIndex = nil
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                }
            }
            .padding(AppSpacing.screenPadding)
            .padding(.bottom, 100)
            .animation(.easeInOut(duration: 0.3), value: viewModel.livePhotos.count)
        }
    }
    
    // MARK: - Bottom Action Bar (Normal Mode)
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save ~\(viewModel.formattedTotalSavings)")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(viewModel.convertCount + viewModel.deleteCount) to process")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                PrimaryButton(title: "Apply Changes") {
                    Task {
                        await viewModel.applyChanges()
                    }
                }
                .frame(width: 160)
                .opacity(viewModel.convertCount + viewModel.deleteCount > 0 ? 1 : 0.5)
                .disabled(viewModel.convertCount + viewModel.deleteCount == 0)
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.backgroundSecondary)
        }
    }
    
    // MARK: - Multi-Select Bottom Bar
    
    private var multiSelectBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            VStack(spacing: 12) {
                Text("\(viewModel.selectedIndices.count) selected")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.setSelectedToAction(.keepLive)
                        }
                    } label: {
                        Text("Keep")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.statusSuccess)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.setSelectedToAction(.convert)
                        }
                    } label: {
                        Text("Convert")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.accentBlue)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.setSelectedToAction(.delete)
                        }
                    } label: {
                        Text("Delete")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.statusError)
                            .cornerRadius(10)
                    }
                }
                .opacity(viewModel.selectedIndices.isEmpty ? 0.5 : 1)
                .disabled(viewModel.selectedIndices.isEmpty)
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.backgroundSecondary)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "livephoto",
            iconColor: AppColors.statusWarning,
            title: "No Live Photos",
            description: "You don't have any Live Photos to clean up.",
            buttonTitle: "Back to Photos"
        ) {
            dismiss()
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if viewModel.isProcessing {
                    CircularProgress(
                        progress: viewModel.processingProgress,
                        lineWidth: 6,
                        size: 80,
                        showPercentage: true,
                        gradient: AppGradients.ctaGradient
                    )
                    
                    Text("Processing \(viewModel.processedCount)/\(viewModel.totalToProcess)...")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                        .scaleEffect(1.5)
                    
                    Text("Loading Live Photos...")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Live Photo Card (Large)

struct LivePhotoCard: View {
    @Binding var livePhoto: LivePhotoAsset
    var isExpanded: Bool
    var isMultiSelectMode: Bool
    var isSelected: Bool
    var onThumbnailTap: () -> Void
    var onCardTap: () -> Void
    var onLongPress: () -> Void
    var onActionSelected: (LivePhotoAsset.LivePhotoAction) -> Void
    
    @State private var thumbnail: UIImage?
    
    private var borderColor: Color {
        switch livePhoto.action {
        case .keepLive: return AppColors.statusSuccess
        case .convert: return AppColors.accentBlue
        case .delete: return AppColors.statusError
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: 16) {
                // Selection checkbox (multi-select mode)
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? AppColors.accentBlue : AppColors.textTertiary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Large Thumbnail - тап открывает превью
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .cornerRadius(16)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(AppColors.backgroundCard)
                            .frame(width: 120, height: 120)
                            .cornerRadius(16)
                    }
                    
                    VStack {
                        // Favorite badge at top right
                        HStack {
                            Spacer()
                            if livePhoto.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(4)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        // Live Badge at bottom left
                        HStack {
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.accentBlue, AppColors.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(6)
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .frame(width: 120, height: 120)
                .contentShape(Rectangle())
                .onTapGesture {
                    onThumbnailTap()
                }
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    // Дата как заголовок
                    Text(livePhoto.formattedDate)
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(livePhoto.formattedTotalSize)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Save \(livePhoto.formattedSavings)")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.statusSuccess)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Chevron indicator
                if !isMultiSelectMode {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                onCardTap()
            }
            
            // Expanded action buttons
            if isExpanded && !isMultiSelectMode {
                Divider()
                    .background(AppColors.borderSecondary)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    actionButton(
                        title: "Keep",
                        color: AppColors.statusSuccess,
                        isActive: livePhoto.action == .keepLive
                    ) {
                        onActionSelected(.keepLive)
                    }
                    
                    actionButton(
                        title: "Convert",
                        color: AppColors.accentBlue,
                        isActive: livePhoto.action == .convert
                    ) {
                        onActionSelected(.convert)
                    }
                    
                    actionButton(
                        title: "Delete",
                        color: AppColors.statusError,
                        isActive: livePhoto.action == .delete
                    ) {
                        onActionSelected(.delete)
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: isMultiSelectMode ? (isSelected ? 3 : 0) : 2)
                )
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
        }
        .animation(.easeInOut(duration: 0.2), value: isMultiSelectMode)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func actionButton(title: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subtitleM)
                .foregroundColor(isActive ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? color : color.opacity(0.15))
                )
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        PhotoService.shared.loadThumbnail(
            for: livePhoto.asset,
            size: CGSize(width: 300, height: 300)
        ) { image in
            thumbnail = image
        }
    }
}

// MARK: - Live Photo Player View (UIViewRepresentable)

struct LivePhotoPlayerView: UIViewRepresentable {
    let asset: PHAsset
    
    func makeUIView(context: Context) -> PHLivePhotoView {
        let livePhotoView = PHLivePhotoView()
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.isMuted = false
        loadLivePhoto(into: livePhotoView)
        return livePhotoView
    }
    
    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {}
    
    private func loadLivePhoto(into view: PHLivePhotoView) {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: .aspectFit,
            options: options
        ) { livePhoto, _ in
            DispatchQueue.main.async {
                if let livePhoto = livePhoto {
                    view.livePhoto = livePhoto
                    view.startPlayback(with: .full)
                }
            }
        }
    }
}

// MARK: - Live Photos ViewModel

@MainActor
final class LivePhotosViewModel: ObservableObject {
    
    @Published var livePhotos: [LivePhotoAsset] = []
    @Published var isLoading: Bool = true
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0
    @Published var processedCount: Int = 0
    @Published var totalToProcess: Int = 0
    
    @Published var isMultiSelectMode: Bool = false
    @Published var selectedIndices: Set<Int> = []
    
    private let photoService = PhotoService.shared
    
    var totalSavings: Int64 {
        livePhotos.reduce(Int64(0)) { result, photo in
            switch photo.action {
            case .convert, .delete:
                return result + photo.videoSize
            case .keepLive:
                return result
            }
        }
    }
    
    var formattedTotalSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavings, countStyle: .file)
    }
    
    var convertCount: Int {
        livePhotos.filter { $0.action == .convert }.count
    }
    
    var deleteCount: Int {
        livePhotos.filter { $0.action == .delete }.count
    }
    
    var keepCount: Int {
        livePhotos.filter { $0.action == .keepLive }.count
    }
    
    func loadLivePhotos() async {
        isLoading = true
        livePhotos = photoService.fetchLivePhotosAsModels()
        isLoading = false
    }
    
    func enterMultiSelectMode(startingWith index: Int) {
        isMultiSelectMode = true
        selectedIndices = [index]
    }
    
    func exitMultiSelectMode() {
        isMultiSelectMode = false
        selectedIndices.removeAll()
    }
    
    func toggleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    func setSelectedToAction(_ action: LivePhotoAsset.LivePhotoAction) {
        for index in selectedIndices {
            if index < livePhotos.count {
                livePhotos[index].action = action
            }
        }
        exitMultiSelectMode()
    }
    
    func applyChanges() async {
        let toProcess = livePhotos.enumerated().filter { $0.element.action != .keepLive }
        guard !toProcess.isEmpty else { return }
        
        isProcessing = true
        totalToProcess = toProcess.count
        processedCount = 0
        processingProgress = 0
        
        var successIds: Set<String> = []
        
        for (_, photo) in toProcess {
            do {
                switch photo.action {
                case .delete:
                    try await photoService.deletePhotos([photo.asset])
                    successIds.insert(photo.id)
                    
                case .convert:
                    try await photoService.convertLivePhotoToStill(photo.asset)
                    successIds.insert(photo.id)
                    
                case .keepLive:
                    break
                }
            } catch {
                print("Failed to process Live Photo: \(error)")
            }
            
            processedCount += 1
            processingProgress = Double(processedCount) / Double(totalToProcess)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            livePhotos.removeAll { successIds.contains($0.id) }
        }
        
        if !successIds.isEmpty {
            SubscriptionService.shared.recordCleaning(count: successIds.count)
        }
        
        isProcessing = false
    }
    
    func setAllToConvert() {
        for i in livePhotos.indices {
            livePhotos[i].action = .convert
        }
    }
    
    func setAllToDelete() {
        for i in livePhotos.indices {
            livePhotos[i].action = .delete
        }
    }
    
    func setAllToKeep() {
        for i in livePhotos.indices {
            livePhotos[i].action = .keepLive
        }
    }
}

// MARK: - Preview

struct LivePhotosView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LivePhotosView()
        }
    }
}
