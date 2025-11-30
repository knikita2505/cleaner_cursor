import SwiftUI
import Photos

// MARK: - Live Photos View

struct LivePhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = LivePhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showProcessingAlert: Bool = false
    
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
                    bottomActionBar
                }
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
                Menu {
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
                    
                    Button {
                        viewModel.setAllToKeep()
                    } label: {
                        Label("Keep All", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .task {
            await viewModel.loadLivePhotos()
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppColors.statusWarning)
            
            Text("Convert Live Photos to still images to save storage.")
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
            
            // Action breakdown
            HStack(spacing: 16) {
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
                
                actionBadge(
                    count: viewModel.keepCount,
                    label: "Keep",
                    color: AppColors.statusSuccess
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
                ForEach(viewModel.livePhotos.indices, id: \.self) { index in
                    LivePhotoRow(
                        livePhoto: $viewModel.livePhotos[index]
                    )
                }
            }
            .padding(AppSpacing.screenPadding)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Bottom Action Bar
    
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
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.backgroundSecondary)
        }
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
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack(spacing: 14) {
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
            
            // Action Picker
            Menu {
                ForEach(LivePhotoAsset.LivePhotoAction.allCases, id: \.rawValue) { action in
                    Button {
                        livePhoto.action = action
                    } label: {
                        HStack {
                            Text(action.rawValue)
                            if livePhoto.action == action {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
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
        .background(AppColors.backgroundCard)
        .cornerRadius(AppSpacing.buttonRadius)
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
    @Published var isLoading: Bool = true // Start with loading state
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0
    @Published var processedCount: Int = 0
    @Published var totalToProcess: Int = 0
    
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
    
    func applyChanges() async {
        let toProcess = livePhotos.filter { $0.action != .keepLive }
        guard !toProcess.isEmpty else { return }
        
        isProcessing = true
        totalToProcess = toProcess.count
        processedCount = 0
        processingProgress = 0
        
        var successCount = 0
        
        for photo in toProcess {
            do {
                switch photo.action {
                case .delete:
                    try await photoService.deletePhotos([photo.asset])
                    successCount += 1
                    
                case .convert:
                    // Real conversion: extract still image and save, then delete original
                    try await photoService.convertLivePhotoToStill(photo.asset)
                    successCount += 1
                    
                case .keepLive:
                    break
                }
                
                processedCount += 1
                processingProgress = Double(processedCount) / Double(totalToProcess)
                
                // Remove from list
                if let index = livePhotos.firstIndex(where: { $0.id == photo.id }) {
                    livePhotos.remove(at: index)
                }
                
            } catch {
                print("Failed to process Live Photo: \(error)")
                processedCount += 1
                processingProgress = Double(processedCount) / Double(totalToProcess)
            }
        }
        
        // Record cleaning
        if successCount > 0 {
            SubscriptionService.shared.recordCleaning(count: successCount)
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

