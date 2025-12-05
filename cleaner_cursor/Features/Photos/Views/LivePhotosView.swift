import SwiftUI
import Photos

// MARK: - Live Photos View

struct LivePhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = LivePhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showActionPopup: Bool = false
    @State private var selectedPhotoIndex: Int? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.livePhotos.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Info Banner
                    infoBanner
                    
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
            
            // Custom Action Popup
            if showActionPopup, let index = selectedPhotoIndex, index < viewModel.livePhotos.count {
                actionPopup(for: index)
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
    }
    
    // MARK: - Custom Action Popup
    
    private func actionPopup(for index: Int) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showActionPopup = false
                        selectedPhotoIndex = nil
                    }
                }
            
            // Popup card
            VStack(spacing: 0) {
                // Header
                Text("Choose Action")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                Divider()
                    .background(AppColors.borderSecondary)
                
                // Actions
                VStack(spacing: 0) {
                    actionButton(
                        icon: "checkmark.circle.fill",
                        title: "Keep Live Photo",
                        subtitle: "No changes",
                        color: AppColors.statusSuccess,
                        isSelected: viewModel.livePhotos[index].action == .keepLive
                    ) {
                        viewModel.livePhotos[index].action = .keepLive
                        closePopup()
                    }
                    
                    Divider()
                        .background(AppColors.borderSecondary)
                        .padding(.horizontal, 16)
                    
                    actionButton(
                        icon: "photo.fill",
                        title: "Convert to Still",
                        subtitle: "Save \(viewModel.livePhotos[index].formattedSavings)",
                        color: AppColors.accentBlue,
                        isSelected: viewModel.livePhotos[index].action == .convert
                    ) {
                        viewModel.livePhotos[index].action = .convert
                        closePopup()
                    }
                    
                    Divider()
                        .background(AppColors.borderSecondary)
                        .padding(.horizontal, 16)
                    
                    actionButton(
                        icon: "trash.fill",
                        title: "Delete",
                        subtitle: "Remove completely",
                        color: AppColors.statusError,
                        isSelected: viewModel.livePhotos[index].action == .delete
                    ) {
                        viewModel.livePhotos[index].action = .delete
                        closePopup()
                    }
                }
                
                // Cancel button
                Button {
                    closePopup()
                } label: {
                    Text("Cancel")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(16)
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
        .transition(.opacity)
    }
    
    private func actionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? color.opacity(0.1) : Color.clear)
        }
    }
    
    private func closePopup() {
        withAnimation(.easeOut(duration: 0.2)) {
            showActionPopup = false
            selectedPhotoIndex = nil
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppColors.statusWarning)
            
            Text(viewModel.isMultiSelectMode 
                 ? "Tap photos to select, then choose action below."
                 : "Tap a photo to change action. Long press for multi-select.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.statusWarning.opacity(0.1))
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
                    Text("\(viewModel.livePhotos.count)")
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Live Photos")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Action breakdown - новый порядок: Keep, Convert, Delete
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
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.livePhotos.enumerated()), id: \.element.id) { index, livePhoto in
                    LivePhotoRow(
                        livePhoto: Binding(
                            get: { viewModel.livePhotos[index] },
                            set: { viewModel.livePhotos[index] = $0 }
                        ),
                        isMultiSelectMode: viewModel.isMultiSelectMode,
                        isSelected: viewModel.selectedIndices.contains(index),
                        onTap: {
                            if viewModel.isMultiSelectMode {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleSelection(index)
                                }
                            } else {
                                selectedPhotoIndex = index
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showActionPopup = true
                                }
                            }
                        },
                        onLongPress: {
                            if !viewModel.isMultiSelectMode {
                                HapticManager.impact(.medium)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.enterMultiSelectMode(startingWith: index)
                                }
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
                // Selection count
                Text("\(viewModel.selectedIndices.count) selected")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                // Action buttons - новый порядок: Keep, Convert, Delete
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.setSelectedToAction(.keepLive)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Keep")
                        }
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
                        HStack {
                            Image(systemName: "photo")
                            Text("Convert")
                        }
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
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
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

// MARK: - Live Photo Row

struct LivePhotoRow: View {
    @Binding var livePhoto: LivePhotoAsset
    var isMultiSelectMode: Bool
    var isSelected: Bool
    var onTap: () -> Void
    var onLongPress: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack(spacing: 14) {
            // Selection checkbox (multi-select mode)
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppColors.accentBlue : AppColors.textTertiary)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Thumbnail with Live badge
            ZStack(alignment: .bottomLeading) {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundCard)
                        .frame(width: 70, height: 70)
                        .cornerRadius(10)
                }
                
                // Live Badge
                Text("LIVE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .padding(4)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(livePhoto.formattedDate)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(livePhoto.formattedTotalSize) • Live Photo")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("Save \(livePhoto.formattedSavings) by converting")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            Spacer()
            
            // Action indicator (not in multi-select mode)
            if !isMultiSelectMode {
                Text(livePhoto.action.rawValue)
                    .font(AppFonts.caption)
                    .foregroundColor(actionColor(livePhoto.action))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(actionColor(livePhoto.action).opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                .fill(AppColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                        .stroke(isSelected ? AppColors.accentBlue : Color.clear, lineWidth: 2)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress()
        }
        .animation(.easeInOut(duration: 0.2), value: isMultiSelectMode)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        PhotoService.shared.loadThumbnail(
            for: livePhoto.asset,
            size: CGSize(width: 200, height: 200)
        ) { image in
            thumbnail = image
        }
    }
    
    private func actionColor(_ action: LivePhotoAsset.LivePhotoAction) -> Color {
        switch action {
        case .keepLive: return AppColors.statusSuccess
        case .convert: return AppColors.accentBlue
        case .delete: return AppColors.statusError
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
    
    // Multi-select
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
    
    // MARK: - Load
    
    func loadLivePhotos() async {
        isLoading = true
        livePhotos = photoService.fetchLivePhotosAsModels()
        isLoading = false
    }
    
    // MARK: - Multi-Select
    
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
    
    // MARK: - Apply Changes
    
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
        
        // Remove processed photos from list with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            livePhotos.removeAll { successIds.contains($0.id) }
        }
        
        // Record cleaning
        if !successIds.isEmpty {
            SubscriptionService.shared.recordCleaning(count: successIds.count)
        }
        
        isProcessing = false
    }
    
    // MARK: - Bulk Actions
    
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
