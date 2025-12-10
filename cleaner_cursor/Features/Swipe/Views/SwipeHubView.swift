import SwiftUI
import Photos

// MARK: - Swipe Hub View
/// Хаб-экран режима Swipe Clean с группировкой по месяцам (swipe_hub.md)

struct SwipeHubView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SwipeHubViewModel()
    @ObservedObject private var progressService = SwipeProgressService.shared
    @State private var refreshTrigger = UUID()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
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
                // Refresh on appear to update progress
                refreshTrigger = UUID()
                Task {
                    await viewModel.loadPhotos()
                }
            }
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
                    .trim(from: 0, to: viewModel.totalProgress / 100)
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
                    .animation(.easeOut(duration: 0.5), value: viewModel.totalProgress)
                
                // Percentage
                VStack(spacing: 2) {
                    Text("\(Int(viewModel.totalProgress))%")
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
    
    var body: some View {
        NavigationLink(value: group) {
            HStack(spacing: 16) {
                // Month icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBackground)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
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
    
    private var iconBackground: Color {
        if progress.isCompleted {
            return AppColors.statusSuccess.opacity(0.15)
        } else if progress.reviewedCount > 0 {
            return AppColors.accentBlue.opacity(0.15)
        } else {
            return AppColors.textTertiary.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        if progress.isCompleted {
            return AppColors.statusSuccess
        } else if progress.reviewedCount > 0 {
            return AppColors.accentBlue
        } else {
            return AppColors.textTertiary
        }
    }
    
    private var iconName: String {
        if progress.isCompleted {
            return "checkmark"
        } else {
            return "calendar"
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

