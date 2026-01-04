import SwiftUI
import Photos

// MARK: - Swipe Session View
/// Tinder-style свайп фотографий для выбранного месяца (swipe_session.md)

struct SwipeSessionView: View {
    
    // MARK: - Properties
    
    let monthGroup: PhotoMonthGroup
    
    @StateObject private var viewModel: SwipeSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showKeepOverlay: Bool = false
    @State private var showDeleteOverlay: Bool = false
    @State private var cardScale: CGFloat = 1.0
    @State private var showExitConfirmation: Bool = false
    
    // MARK: - Init
    
    init(monthGroup: PhotoMonthGroup) {
        self.monthGroup = monthGroup
        self._viewModel = StateObject(wrappedValue: SwipeSessionViewModel(monthGroup: monthGroup))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.showSummary {
                summaryView
            } else if viewModel.isLoading {
                LoadingStateView(title: "Loading photos...")
            } else if viewModel.availablePhotos.isEmpty {
                completedState
            } else {
                swipeContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // If on summary screen and can continue - go back to session
                    if viewModel.showSummary && viewModel.canContinueSwiping {
                        viewModel.showSummary = false
                    } else {
                        // Show confirmation if there are unsaved decisions
                        if viewModel.sessionDecisions.isEmpty {
                            dismiss()
                        } else {
                            showExitConfirmation = true
                        }
                    }
                } label: {
                    // Show back arrow only if on summary AND can continue swiping
                    Image(systemName: (viewModel.showSummary && viewModel.canContinueSwiping) ? "chevron.left" : "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(viewModel.showSummary ? "Summary" : monthGroup.shortDisplayName)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.sessionDecisions.isEmpty && !viewModel.showSummary {
                    Button("Apply") {
                        viewModel.showSummary = true
                    }
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .confirmationDialog("Discard Session?", isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("You have \(viewModel.sessionDecisions.count) unsaved decisions. If you leave now, your progress won't be saved.")
        }
        .alert("Deletion Cancelled", isPresented: $viewModel.showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.deleteErrorMessage)
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
    
    // MARK: - Swipe Content
    
    private var swipeContent: some View {
        VStack(spacing: 0) {
            // Progress Counter
            progressCounter
                .padding(.top, 8)
            
            Spacer()
            
            // Card Stack
            ZStack {
                // Next card (behind)
                if viewModel.currentIndex + 1 < viewModel.availablePhotos.count {
                    let nextAsset = viewModel.availablePhotos[viewModel.currentIndex + 1]
                    PhotoSwipeCard2(
                        asset: nextAsset,
                        showKeepOverlay: .constant(false),
                        showDeleteOverlay: .constant(false)
                    )
                    .id("next-\(nextAsset.id)")
                    .scaleEffect(0.92)
                    .opacity(0.4)
                }
                
                // Current card
                if viewModel.currentIndex < viewModel.availablePhotos.count {
                    let currentAsset = viewModel.availablePhotos[viewModel.currentIndex]
                    PhotoSwipeCard2(
                        asset: currentAsset,
                        showKeepOverlay: $showKeepOverlay,
                        showDeleteOverlay: $showDeleteOverlay
                    )
                    .id("current-\(currentAsset.id)")
                    .offset(offset)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(cardScale)
                    .gesture(dragGesture)
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: offset)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            Spacer()
            
            // Bottom Actions
            bottomActions
        }
    }
    
    // MARK: - Progress Counter
    
    private var progressCounter: some View {
        VStack(spacing: 8) {
            Text("Photo \(viewModel.currentIndex + 1) of \(viewModel.availablePhotos.count)")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textSecondary)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.progressInactive)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentBlue, AppColors.accentPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.sessionProgress, height: 4)
                        .animation(.easeOut(duration: 0.3), value: viewModel.sessionProgress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 16) {
            // Undo button - always reserve space, but hide when not available
            Button {
                viewModel.undoLast()
                HapticManager.lightImpact()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .medium))
                    Text("Undo")
                        .font(AppFonts.bodyM)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(20)
            }
            .opacity(viewModel.canUndo ? 1 : 0)
            .disabled(!viewModel.canUndo)
            
            // Action Buttons
            HStack(spacing: 40) {
                // Delete Button
                ActionCircleButton(
                    icon: "trash.fill",
                    color: AppColors.statusError,
                    size: 64
                ) {
                    performSwipe(decision: .delete, direction: .left)
                }
                
                // Keep Button
                ActionCircleButton(
                    icon: "heart.fill",
                    color: AppColors.statusSuccess,
                    size: 64
                ) {
                    performSwipe(decision: .keep, direction: .right)
                }
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width / 25)
                
                // Scale down slightly during drag
                let dragDistance = abs(value.translation.width)
                cardScale = max(0.95, 1 - dragDistance / 2000)
                
                // Update overlays based on swipe direction
                withAnimation(.easeOut(duration: 0.1)) {
                    // Swipe RIGHT = Keep (green)
                    showKeepOverlay = value.translation.width > 50
                    // Swipe LEFT = Delete (red)
                    showDeleteOverlay = value.translation.width < -50
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                if value.translation.width > threshold || velocity > 200 {
                    // Swipe right - Keep
                    performSwipe(decision: .keep, direction: .right)
                } else if value.translation.width < -threshold || velocity < -200 {
                    // Swipe left - Delete
                    performSwipe(decision: .delete, direction: .left)
                } else {
                    // Return to center
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        resetCard()
                    }
                }
            }
    }
    
    private func performSwipe(decision: SwipeDecision, direction: SwipeDirection) {
        let xOffset: CGFloat = direction == .right ? 500 : -500
        
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(width: xOffset, height: 0)
            rotation = direction == .right ? 15 : -15
        }
        
        HapticManager.mediumImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewModel.makeDecision(decision)
            resetCard()
        }
    }
    
    private func resetCard() {
        offset = .zero
        rotation = 0
        cardScale = 1.0
        showKeepOverlay = false
        showDeleteOverlay = false
    }
    
    // MARK: - Completed State
    
    private var completedState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.statusSuccess.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            VStack(spacing: 8) {
                Text("All Done!")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("You've reviewed all photos in \(monthGroup.displayName)")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            SecondaryButton(title: "Go Back") {
                dismiss()
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Summary View
    
    private var summaryView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.accentBlue)
            }
            
            // Title
            VStack(spacing: 12) {
                Text("Session Summary")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(monthGroup.displayName)")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Stats
            HStack(spacing: 20) {
                statCard(
                    icon: "trash.fill",
                    value: "\(viewModel.toDeleteCount)",
                    label: "To Delete",
                    color: AppColors.statusError
                )
                
                statCard(
                    icon: "heart.fill",
                    value: "\(viewModel.keptCount)",
                    label: "Kept",
                    color: AppColors.statusSuccess
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                // Apply button - saves progress and deletes photos if any
                PrimaryButton(
                    title: viewModel.toDeleteCount > 0 
                        ? "Apply & Delete \(viewModel.toDeleteCount) Photos" 
                        : "Apply Changes",
                    icon: viewModel.toDeleteCount > 0 ? "trash" : "checkmark",
                    isLoading: viewModel.isDeleting
                ) {
                    Task {
                        let success = await viewModel.applySession()
                        if success {
                            dismiss()
                        }
                    }
                }
                
                // Show different button based on session state
                if viewModel.canContinueSwiping {
                    // Can continue - show "Continue Swiping"
                    SecondaryButton(title: "Continue Swiping") {
                        viewModel.showSummary = false
                    }
                } else {
                    // Session complete - show "Discard Session"
                    SecondaryButton(title: "Discard Session") {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.titleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
}

// MARK: - Swipe Direction

private enum SwipeDirection {
    case left
    case right
}

// MARK: - Photo Swipe Card

struct PhotoSwipeCard2: View {
    let asset: PhotoAsset
    @Binding var showKeepOverlay: Bool
    @Binding var showDeleteOverlay: Bool
    
    @State private var image: UIImage?
    @State private var fileSize: Int64 = 0
    @State private var fileSizeLoaded = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Photo
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.backgroundCard)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                        )
                }
                
                // Keep Overlay (Green - Right swipe)
                if showKeepOverlay {
                    ZStack {
                        Color.green.opacity(0.25)
                        
                        VStack {
                            Text("KEEP")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(.green)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.green, lineWidth: 5)
                                )
                                .rotationEffect(.degrees(-15))
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.leading, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .transition(.opacity)
                }
                
                // Delete Overlay (Red - Left swipe)
                if showDeleteOverlay {
                    ZStack {
                        Color.red.opacity(0.25)
                        
                        VStack {
                            Text("DELETE")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 5)
                                )
                                .rotationEffect(.degrees(15))
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 24)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .transition(.opacity)
                }
                
                // Bottom Info Gradient
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Favorite badge
                        if asset.isFavorite {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                Text("Favorite")
                                    .font(AppFonts.caption)
                            }
                            .foregroundColor(.pink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        
                        // Date and size
                        HStack(spacing: 8) {
                            Text(asset.formattedDate)
                                .font(AppFonts.bodyM)
                            
                            Text("•")
                                .opacity(0.6)
                            
                            // Lazy loaded file size
                            if fileSizeLoaded {
                                Text(formattedFileSize)
                                    .font(AppFonts.bodyM)
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.6)
                            }
                            
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .onAppear {
            loadImage()
            loadFileSize()
        }
    }
    
    private var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            .replacingOccurrences(of: "Zero", with: "0")
    }
    
    @MainActor
    private func loadImage() {
        PhotoService.shared.loadThumbnail(for: asset.asset, size: CGSize(width: 800, height: 1000)) { img in
            withAnimation(.easeIn(duration: 0.2)) {
                self.image = img
            }
        }
    }
    
    private func loadFileSize() {
        Task.detached(priority: .utility) {
            let resources = PHAssetResource.assetResources(for: asset.asset)
            let size = resources.first.flatMap { resource in
                (resource.value(forKey: "fileSize") as? Int64)
            } ?? 0
            
            await MainActor.run {
                self.fileSize = size
                self.fileSizeLoaded = true
            }
        }
    }
}

// MARK: - Action Circle Button

struct ActionCircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
                
                Circle()
                    .stroke(color, lineWidth: 3)
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// MARK: - Press Events Modifier

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - Swipe Session ViewModel

@MainActor
class SwipeSessionViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published var availablePhotos: [PhotoAsset] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = true
    @Published var isDeleting = false
    @Published var showSummary = false
    @Published var sessionDecisions: [(photoId: String, decision: SwipeDecision)] = []
    @Published var showDeleteError = false
    @Published var deleteErrorMessage = ""
    
    // MARK: - Properties
    
    let monthGroup: PhotoMonthGroup
    private let progressService = SwipeProgressService.shared
    private let photoService = PhotoService.shared
    
    // MARK: - Computed
    
    var toDeleteCount: Int {
        sessionDecisions.filter { $0.decision == .delete }.count
    }
    
    var keptCount: Int {
        sessionDecisions.filter { $0.decision == .keep }.count
    }
    
    var canUndo: Bool {
        !sessionDecisions.isEmpty
    }
    
    var sessionProgress: CGFloat {
        guard !availablePhotos.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(availablePhotos.count)
    }
    
    /// True if all photos have been processed (no more to swipe)
    var isSessionComplete: Bool {
        currentIndex >= availablePhotos.count - 1 && !sessionDecisions.isEmpty
    }
    
    /// True if there are more photos to swipe
    var canContinueSwiping: Bool {
        currentIndex < availablePhotos.count - 1
    }
    
    // MARK: - Init
    
    init(monthGroup: PhotoMonthGroup) {
        self.monthGroup = monthGroup
    }
    
    // MARK: - Methods
    
    func loadPhotos() {
        isLoading = true
        
        // Filter out already reviewed photos (from previous sessions)
        availablePhotos = monthGroup.photos.filter { photo in
            !progressService.isPhotoReviewed(monthKey: monthGroup.monthKey, photoId: photo.id)
        }
        
        isLoading = false
    }
    
    func makeDecision(_ decision: SwipeDecision) {
        guard currentIndex < availablePhotos.count else { return }
        
        let photo = availablePhotos[currentIndex]
        
        // Save decision locally (for this session only, NOT persisted yet)
        sessionDecisions.append((photoId: photo.id, decision: decision))
        
        // Move to next
        if currentIndex < availablePhotos.count - 1 {
            currentIndex += 1
        } else {
            // Session complete
            showSummary = true
        }
    }
    
    func undoLast() {
        guard !sessionDecisions.isEmpty else { return }
        
        // Remove last decision from local session
        sessionDecisions.removeLast()
        
        // Go back
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    /// Apply session - save progress and optionally delete photos
    func applySession() async -> Bool {
        isDeleting = true
        
        // 1. Save only "keep" decisions first (these are safe)
        let keptDecisions = sessionDecisions.filter { $0.decision == .keep }
        for decision in keptDecisions {
            progressService.updateProgress(
                monthKey: monthGroup.monthKey,
                photoId: decision.photoId,
                decision: decision.decision
            )
        }
        
        // 2. Delete photos marked for deletion
        if toDeleteCount > 0 {
            let idsToDelete = Set(sessionDecisions.filter { $0.decision == .delete }.map { $0.photoId })
            let photosToDelete = monthGroup.photos.filter { idsToDelete.contains($0.id) }
            
            do {
                // Calculate bytes before deletion
                let bytesFreed = photosToDelete.reduce(Int64(0)) { $0 + $1.fileSize }
                
                try await photoService.deletePhotoAssets(photosToDelete)
                
                // Success - now save delete decisions to progress
                for decision in sessionDecisions.filter({ $0.decision == .delete }) {
                    progressService.updateProgress(
                        monthKey: monthGroup.monthKey,
                        photoId: decision.photoId,
                        decision: decision.decision
                    )
                }
                
                // Record to history
                CleaningHistoryService.shared.recordCleaning(
                    type: .swipePhotos,
                    itemsCount: photosToDelete.count,
                    bytesFreed: bytesFreed
                )
                
                // Clear deleted IDs from progress (they no longer exist)
                progressService.clearDeletedIds(monthKey: monthGroup.monthKey)
                
                // Invalidate hub cache since photos were deleted
                SwipeHubViewModel.invalidateCache()
                
                HapticManager.success()
                isDeleting = false
                return true
            } catch {
                print("Failed to delete photos: \(error)")
                deleteErrorMessage = "Photo deletion was cancelled. Please allow deletion to complete the cleanup."
                showDeleteError = true
                HapticManager.error()
                isDeleting = false
                return false
            }
        } else {
            HapticManager.success()
            isDeleting = false
            return true
        }
    }
}

// MARK: - Preview

struct SwipeSessionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SwipeSessionView(
                monthGroup: PhotoMonthGroup(
                    id: "2024-12",
                    month: Date(),
                    photos: []
                )
            )
        }
    }
}

