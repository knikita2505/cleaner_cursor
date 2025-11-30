import SwiftUI
import Photos

// MARK: - Swipe Clean View
/// Tinder-style свайп для очистки фото (photos_swipe_clean.md)

struct SwipeCleanView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SwipeCleanViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showKeepOverlay: Bool = false
    @State private var showDeleteOverlay: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingStateView(title: "Loading photos...")
            } else if viewModel.photos.isEmpty {
                emptyState
            } else if viewModel.showSummary {
                summaryView
            } else {
                swipeContent
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadPhotos()
            }
        }
    }
    
    // MARK: - Swipe Content
    
    private var swipeContent: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            Spacer()
            
            // Card Stack
            ZStack {
                // Next card (behind)
                if viewModel.currentIndex + 1 < viewModel.photos.count {
                    PhotoSwipeCard(
                        asset: viewModel.photos[viewModel.currentIndex + 1],
                        showKeepOverlay: .constant(false),
                        showDeleteOverlay: .constant(false)
                    )
                    .scaleEffect(0.95)
                    .opacity(0.5)
                }
                
                // Current card
                if viewModel.currentIndex < viewModel.photos.count {
                    PhotoSwipeCard(
                        asset: viewModel.photos[viewModel.currentIndex],
                        showKeepOverlay: $showKeepOverlay,
                        showDeleteOverlay: $showDeleteOverlay
                    )
                    .offset(offset)
                    .rotationEffect(.degrees(rotation))
                    .gesture(dragGesture)
                    .animation(.interactiveSpring(), value: offset)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            Spacer()
            
            // Bottom Hints
            bottomHints
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Close
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Progress
            Text("\(viewModel.currentIndex + 1) / \(viewModel.photos.count)")
                .font(AppFonts.subtitleM)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Skip
            Button {
                viewModel.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Hints
    
    private var bottomHints: some View {
        HStack {
            // Keep hint
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Keep")
                    .font(AppFonts.subtitleM)
            }
            .foregroundColor(AppColors.statusSuccess)
            .opacity(showKeepOverlay ? 1.0 : 0.5)
            
            Spacer()
            
            // Delete hint
            HStack(spacing: 8) {
                Text("Delete")
                    .font(AppFonts.subtitleM)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(AppColors.statusError)
            .opacity(showDeleteOverlay ? 1.0 : 0.5)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width / 20)
                
                // Update overlays
                withAnimation(.easeOut(duration: 0.1)) {
                    showKeepOverlay = value.translation.width < -50
                    showDeleteOverlay = value.translation.width > 50
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                
                if value.translation.width > threshold {
                    // Swipe right - Delete
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: 500, height: 0)
                    }
                    HapticManager.mediumImpact()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.markForDeletion()
                        resetCard()
                    }
                } else if value.translation.width < -threshold {
                    // Swipe left - Keep
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: -500, height: 0)
                    }
                    HapticManager.lightImpact()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.keep()
                        resetCard()
                    }
                } else {
                    // Return to center
                    withAnimation(.spring()) {
                        offset = .zero
                        rotation = 0
                        showKeepOverlay = false
                        showDeleteOverlay = false
                    }
                }
            }
    }
    
    private func resetCard() {
        offset = .zero
        rotation = 0
        showKeepOverlay = false
        showDeleteOverlay = false
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                icon: "hand.draw",
                iconColor: AppColors.accentPurple,
                title: "No Photos to Swipe",
                description: "You don't have many photos to clean with swipe.",
                buttonTitle: "Go Back"
            ) {
                dismiss()
            }
        }
    }
    
    // MARK: - Summary View
    
    private var summaryView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(AppColors.statusSuccess.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            // Title
            VStack(spacing: 12) {
                Text("Swipe session complete!")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("You marked \(viewModel.toDelete.count) photos for deletion\nand kept \(viewModel.kept.count) photos.")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Stats
            HStack(spacing: 20) {
                statCard(
                    icon: "trash",
                    value: "\(viewModel.toDelete.count)",
                    label: "To Delete",
                    color: AppColors.statusError
                )
                
                statCard(
                    icon: "heart.fill",
                    value: "\(viewModel.kept.count)",
                    label: "Kept",
                    color: AppColors.statusSuccess
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                if !viewModel.toDelete.isEmpty {
                    PrimaryButton(
                        title: "Delete \(viewModel.toDelete.count) Photos",
                        icon: "trash",
                        isLoading: viewModel.isDeleting
                    ) {
                        Task {
                            await viewModel.confirmDeletion()
                            dismiss()
                        }
                    }
                }
                
                SecondaryButton(title: "Done") {
                    dismiss()
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

// MARK: - Photo Swipe Card

struct PhotoSwipeCard: View {
    let asset: PhotoAsset
    @Binding var showKeepOverlay: Bool
    @Binding var showDeleteOverlay: Bool
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            // Photo
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .clipped()
            } else {
                Rectangle()
                    .fill(AppColors.backgroundCard)
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                    )
            }
            
            // Keep Overlay
            if showKeepOverlay {
                ZStack {
                    Color.green.opacity(0.3)
                    
                    VStack {
                        Text("KEEP")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(-20))
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Delete Overlay
            if showDeleteOverlay {
                ZStack {
                    Color.red.opacity(0.3)
                    
                    VStack {
                        Text("DELETE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(20))
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            // Bottom Info
            VStack {
                Spacer()
                
                // Type badge
                HStack {
                    if asset.isScreenshot {
                        Text("Screenshot")
                            .font(AppFonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColors.accentBlue)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(12)
                
                // Info bar
                HStack {
                    Text(asset.formattedDate)
                        .font(AppFonts.caption)
                        .foregroundColor(.white)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(asset.formattedSize)
                        .font(AppFonts.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
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
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            loadImage()
        }
    }
    
    @MainActor
    private func loadImage() {
        PhotoService.shared.loadThumbnail(for: asset.asset, size: CGSize(width: 600, height: 800)) { img in
            self.image = img
        }
    }
}

// MARK: - Swipe Clean ViewModel

@MainActor
class SwipeCleanViewModel: ObservableObject {
    
    @Published var photos: [PhotoAsset] = []
    @Published var currentIndex: Int = 0
    @Published var toDelete: [PhotoAsset] = []
    @Published var kept: [PhotoAsset] = []
    @Published var isLoading: Bool = true
    @Published var isDeleting: Bool = false
    @Published var showSummary: Bool = false
    
    private let photoService = PhotoService.shared
    private let maxPhotos = 100 // Limit session length
    
    func loadPhotos() async {
        isLoading = true
        
        // Combine screenshots and similar photos for swipe
        var candidates: [PhotoAsset] = []
        
        // Add screenshots
        candidates.append(contentsOf: photoService.fetchScreenshotsAsAssets())
        
        // Add similar photos
        let similar = photoService.findSimilarPhotos()
        for group in similar {
            candidates.append(contentsOf: group.assets)
        }
        
        // Shuffle and limit
        photos = Array(candidates.shuffled().prefix(maxPhotos))
        
        isLoading = false
    }
    
    func markForDeletion() {
        guard currentIndex < photos.count else { return }
        toDelete.append(photos[currentIndex])
        moveToNext()
    }
    
    func keep() {
        guard currentIndex < photos.count else { return }
        kept.append(photos[currentIndex])
        moveToNext()
    }
    
    func skip() {
        moveToNext()
    }
    
    private func moveToNext() {
        if currentIndex < photos.count - 1 {
            currentIndex += 1
        } else {
            showSummary = true
        }
    }
    
    func confirmDeletion() async {
        guard !toDelete.isEmpty else { return }
        
        isDeleting = true
        
        do {
            try await photoService.deletePhotoAssets(toDelete)
            HapticManager.success()
        } catch {
            print("Delete failed: \(error)")
            HapticManager.error()
        }
        
        isDeleting = false
    }
}

// MARK: - Preview

struct SwipeCleanView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCleanView()
    }
}

