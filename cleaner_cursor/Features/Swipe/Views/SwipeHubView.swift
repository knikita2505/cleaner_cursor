import SwiftUI
import Photos

// MARK: - Swipe Hub View
/// Хаб-экран режима Swipe Clean с группировкой по месяцам (swipe_hub.md)

struct SwipeHubView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SwipeHubViewModel()
    @ObservedObject private var photoService = PhotoService.shared
    @ObservedObject private var progressService = SwipeProgressService.shared
    @State private var refreshTrigger = UUID()
    @State private var hasAppeared: Bool = false
    @State private var showFeatureTip: Bool = false
    
    private let tipService = FeatureTipService.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                if !photoService.isAuthorized {
                    permissionRequiredView
                } else if viewModel.isLoading {
                    LoadingStateView(title: "Loading photos...")
                } else if viewModel.monthGroups.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .id(refreshTrigger)
            .navigationTitle("Swipe Photos")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: PhotoMonthGroup.self) { month in
                SwipeSessionView(monthGroup: month)
            }
            .onAppear {
                // Invalidate cache and refresh to ensure fresh data
                SwipeHubViewModel.invalidateCache()
                refreshTrigger = UUID()
                
                guard !hasAppeared else {
                    // Just refresh authorization status on subsequent appears
                    photoService.checkAuthorizationStatus()
                    return
                }
                hasAppeared = true
                
                // Show feature tip on first visit
                if tipService.shouldShowTip(for: .swipe) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFeatureTip = true
                    }
                }
                
                Task {
                    // Check/request authorization
                    if !photoService.isAuthorized {
                        _ = await photoService.requestAuthorization()
                    }
                    
                    // Load photos if authorized
                    if photoService.isAuthorized {
                        await viewModel.loadPhotos()
                    }
                }
            }
            .fullScreenCover(isPresented: $showFeatureTip) {
                FeatureTipView(tipData: .swipe) {
                    tipService.markTipAsShown(for: .swipe)
                    showFeatureTip = false
                }
            }
        }
    }
    
    // MARK: - Permission Required View
    
    private var permissionRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Photos Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("To swipe through your photos, we need access to your photo library.")
                .font(.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Content
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Header
                summaryHeader
                
                // Month List
                monthList
            }
            .padding(AppSpacing.screenPadding)
        }
    }
    
    // MARK: - Computed Progress
    
    private var totalProgressValue: Double {
        progressService.getTotalProgress()
    }
    
    private var progressDisplayText: String {
        let progress = totalProgressValue
        if progress == 0 {
            return "0%"
        } else if progress < 1 {
            return "<1%"
        } else {
            return "\(Int(progress))%"
        }
    }
    
    // MARK: - Summary Header
    
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppColors.progressInactive, lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: totalProgressValue / 100)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: totalProgressValue)
                
                // Percentage
                VStack(spacing: 2) {
                    Text(progressDisplayText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("sorted")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Queue info
            if viewModel.monthsInQueue > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accentBlue)
                    
                    Text("Months in queue: \(viewModel.monthsInQueue)")
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.accentBlue.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Month List
    
    private var monthList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Month")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.monthGroups) { group in
                    MonthCard(
                        group: group,
                        progress: viewModel.getProgress(for: group.monthKey)
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                icon: "hand.draw",
                iconColor: AppColors.accentPurple,
                title: "No Photos to Swipe",
                description: "You don't have enough photos to use the swipe feature."
            )
        }
    }
}

// MARK: - Month Card

struct MonthCard: View {
    let group: PhotoMonthGroup
    let progress: MonthProgress
    
    // Get up to 3 photos for preview stack
    private var previewPhotos: [PhotoAsset] {
        Array(group.photos.prefix(3))
    }
    
    var body: some View {
        NavigationLink(value: group) {
            HStack(spacing: 16) {
                // Photo stack preview (larger size)
                PhotoStackPreview(photos: previewPhotos)
                    .frame(width: 68, height: 68)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.displayName)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        // Use totalCount from progress (original count), not current photos.count
                        Text("\(progress.reviewedCount)/\(progress.totalCount > 0 ? progress.totalCount : group.photos.count)")
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text("reviewed")
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Progress or Arrow
                if progress.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.statusSuccess)
                } else {
                    // Mini progress indicator
                    ZStack {
                        Circle()
                            .stroke(AppColors.progressInactive, lineWidth: 3)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .trim(from: 0, to: progress.progressPercent / 100)
                            .stroke(AppColors.accentBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Photo Stack Preview

struct PhotoStackPreview: View {
    let photos: [PhotoAsset]
    
    var body: some View {
        ZStack {
            // Show up to 3 photos in a fan/stack
            ForEach(Array(photos.enumerated().reversed()), id: \.element.id) { index, photo in
                PhotoStackItem(asset: photo, index: index, total: photos.count)
            }
        }
    }
}

struct PhotoStackItem: View {
    let asset: PhotoAsset
    let index: Int
    let total: Int
    
    @State private var image: UIImage?
    
    // Calculate offset and rotation for fan effect
    private var xOffset: CGFloat {
        CGFloat(index) * 5
    }
    
    private var yOffset: CGFloat {
        CGFloat(index) * -3
    }
    
    private var rotation: Double {
        Double(index - 1) * 6
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.backgroundCard)
                    .frame(width: 52, height: 52)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.backgroundSecondary, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 1, y: 2)
        .offset(x: xOffset, y: yOffset)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        PhotoService.shared.loadThumbnail(for: asset.asset, size: CGSize(width: 100, height: 100)) { img in
            self.image = img
        }
    }
}

// MARK: - Swipe Hub ViewModel

@MainActor
class SwipeHubViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published var monthGroups: [PhotoMonthGroup] = []
    @Published var isLoading = true
    
    // MARK: - Private
    
    private let photoService = PhotoService.shared
    private let progressService = SwipeProgressService.shared
    private static var cachedMonthGroups: [PhotoMonthGroup]?
    private static var lastLoadTime: Date?
    private static let cacheValidityDuration: TimeInterval = 60 // 1 minute cache
    
    // MARK: - Computed
    
    var totalProgress: Double {
        progressService.getTotalProgress()
    }
    
    var monthsInQueue: Int {
        monthGroups.filter { group in
            let progress = getProgress(for: group.monthKey)
            return !progress.isCompleted
        }.count
    }
    
    // MARK: - Methods
    
    func loadPhotos() async {
        // Check cache first
        if let cached = Self.cachedMonthGroups,
           let lastLoad = Self.lastLoadTime,
           Date().timeIntervalSince(lastLoad) < Self.cacheValidityDuration {
            monthGroups = cached
            
            // Update total counts (fast operation)
            for group in monthGroups {
                progressService.setTotalCount(monthKey: group.monthKey, total: group.photos.count)
            }
            
            isLoading = false
            return
        }
        
        isLoading = true
        
        // Fetch and group photos in background - OPTIMIZED: don't calculate fileSize
        let groups = await Task.detached(priority: .userInitiated) { [photoService] in
            self.groupPhotosByMonthOptimized(photoService: photoService)
        }.value
        
        monthGroups = groups
        
        // Cache the results
        Self.cachedMonthGroups = groups
        Self.lastLoadTime = Date()
        
        // Update total counts in progress service
        for group in monthGroups {
            progressService.setTotalCount(monthKey: group.monthKey, total: group.photos.count)
        }
        
        isLoading = false
    }
    
    func getProgress(for monthKey: String) -> MonthProgress {
        progressService.getProgress(for: monthKey)
    }
    
    /// Invalidate cache (call when photos change)
    static func invalidateCache() {
        cachedMonthGroups = nil
        lastLoadTime = nil
    }
    
    /// Optimized grouping - doesn't calculate expensive fileSize for each photo
    private nonisolated func groupPhotosByMonthOptimized(photoService: PhotoService) -> [PhotoMonthGroup] {
        let calendar = Calendar.current
        
        // Fetch raw PHAssets without converting to PhotoAsset (expensive)
        let fetchResult = photoService.fetchAllPhotos()
        
        // Group by year-month with minimal processing
        var grouped: [String: [PHAsset]] = [:]
        var monthDates: [String: Date] = [:]
        
        fetchResult.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { return }
            
            let key = String(format: "%04d-%02d", year, month)
            
            if grouped[key] == nil {
                grouped[key] = []
                monthDates[key] = calendar.date(from: components)
            }
            
            grouped[key]?.append(asset)
        }
        
        // Convert to PhotoMonthGroup - create PhotoAsset with cached fileSize = 0 (lazy load later)
        return grouped.compactMap { key, assets in
            guard let monthDate = monthDates[key] else { return nil }
            
            // Create lightweight PhotoAssets without calculating fileSize
            let photos = assets.map { PhotoAsset(asset: $0, cachedFileSize: 0) }
            
            return PhotoMonthGroup(id: key, month: monthDate, photos: photos)
        }
        .sorted { $0.month > $1.month }
    }
}

// MARK: - Preview

struct SwipeHubView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeHubView()
    }
}

