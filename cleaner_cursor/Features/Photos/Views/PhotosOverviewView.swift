import SwiftUI

// MARK: - Photos Overview View
/// Экран-хаб для всех инструментов очистки фото (photos_overview.md)

struct PhotosOverviewView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = PhotosOverviewViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Summary Card
                    summaryCard
                    
                    // Categories List
                    categoriesList
                    
                    // Rescan Button
                    rescanButton
                    
                    Spacer(minLength: 40)
                }
                .padding(AppSpacing.screenPadding)
            }
            
            // Loading Overlay
            if viewModel.isScanning {
                scanningOverlay
            }
        }
        .navigationTitle("Photos Cleaner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Show info
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            Task {
            await viewModel.scanAllCategories()
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos overview")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You can free up to")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(viewModel.formattedTotalSavings)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // Circular indicator
                CircularProgress(
                    progress: viewModel.cleanableRatio,
                    lineWidth: 6,
                    size: 60,
                    showPercentage: false,
                    gradient: AppGradients.progressGradient
                )
            }
            
            // Progress bar
            StorageProgressBar(progress: viewModel.cleanableRatio)
            
            // Stats
            HStack {
                Text("Photos: \(viewModel.totalPhotosCount)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("•")
                    .foregroundColor(AppColors.textTertiary)
                
                Text("Videos: \(viewModel.totalVideosCount)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    // MARK: - Categories List
    
    private var categoriesList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.categories) { category in
                NavigationLink(value: category.type) {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: PhotoCategory.self) { category in
            destinationView(for: category)
        }
    }
    
    @ViewBuilder
    private func destinationView(for category: PhotoCategory) -> some View {
        switch category {
        case .screenshots:
            ScreenshotsView()
        case .similar:
            SimilarPhotosView()
        case .livePhotos:
            LivePhotosView()
        case .burst:
            BurstPhotosView()
        case .bigFiles:
            BigFilesView()
        case .duplicates:
            DuplicatesView()
        case .highlights:
            HighlightsView()
        }
    }
    
    // MARK: - Rescan Button
    
    private var rescanButton: some View {
        SecondaryButton(title: "Scan all photos again", icon: "arrow.clockwise") {
            Task {
                await viewModel.scanAllCategories()
            }
        }
    }
    
    // MARK: - Scanning Overlay
    
    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.5)
                
                Text("Scanning photos...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: PhotoCategoryInfo
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(category.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(category.type.color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(category.type.rawValue)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(category.count) items • \(category.formattedSize)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, AppSpacing.containerPadding)
        .padding(.vertical, 14)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppSpacing.buttonRadius)
    }
}

// MARK: - Photos Overview ViewModel

@MainActor
class PhotosOverviewViewModel: ObservableObject {
    
    @Published var categories: [PhotoCategoryInfo] = []
    @Published var isScanning: Bool = false
    @Published var totalSavings: Int64 = 0
    @Published var totalPhotosCount: Int = 0
    @Published var totalVideosCount: Int = 0
    
    private let photoService = PhotoService.shared
    private let videoService = VideoService.shared
    
    var formattedTotalSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavings, countStyle: .file)
    }
    
    var cleanableRatio: Double {
        guard totalSavings > 0 else { return 0 }
        return min(Double(totalSavings) / Double(5_000_000_000), 1.0) // Cap at 5GB for visual
    }
    
    func scanAllCategories() async {
        isScanning = true
        
        // Get total counts
        totalPhotosCount = photoService.fetchAllPhotos().count
        totalVideosCount = videoService.fetchAllVideos().count
        
        // Scan each category
        var scannedCategories: [PhotoCategoryInfo] = []
        
        // Duplicates - use cache if available
        let duplicates = photoService.duplicatesScanned ? photoService.cachedDuplicates : photoService.findDuplicates()
        let duplicatesSize = duplicates.reduce(Int64(0)) { $0 + $1.savingsSize }
        scannedCategories.append(PhotoCategoryInfo(
            type: .duplicates,
            count: duplicates.reduce(0) { $0 + $1.count },
            size: duplicatesSize
        ))
        
        // Similar - use cache if available
        let similar = photoService.similarScanned ? photoService.cachedSimilarPhotos : photoService.findSimilarPhotos()
        let similarSize = similar.reduce(Int64(0)) { $0 + $1.savingsSize }
        scannedCategories.append(PhotoCategoryInfo(
            type: .similar,
            count: similar.reduce(0) { $0 + $1.count },
            size: similarSize
        ))
        
        // Screenshots
        let screenshots = photoService.fetchScreenshotsAsAssets()
        let screenshotsSize = screenshots.reduce(Int64(0)) { $0 + $1.fileSize }
        scannedCategories.append(PhotoCategoryInfo(
            type: .screenshots,
            count: screenshots.count,
            size: screenshotsSize
        ))
        
        // Live Photos
        let livePhotos = photoService.fetchLivePhotosAsAssets()
        let livePhotosSize = livePhotos.reduce(Int64(0)) { $0 + $1.fileSize }
        // Estimate savings (video portion is ~60% of Live Photo)
        let livePhotosSavings = Int64(Double(livePhotosSize) * 0.6)
        scannedCategories.append(PhotoCategoryInfo(
            type: .livePhotos,
            count: livePhotos.count,
            size: livePhotosSavings
        ))
        
        // Burst - estimate savings (keep 1 per group)
        let bursts = photoService.fetchBurstGroups()
        var burstsSize: Int64 = 0
        var burstsCount = 0
        for group in bursts {
            burstsCount += group.count
            // Estimate: all but one photo per group
            let groupSize = group.assets.reduce(Int64(0)) { $0 + $1.fileSize }
            if let bestSize = group.assets.first?.fileSize {
                burstsSize += groupSize - bestSize
            }
        }
        scannedCategories.append(PhotoCategoryInfo(
            type: .burst,
            count: burstsCount,
            size: burstsSize
        ))
        
        // Big Files
        let bigFiles = photoService.fetchBigPhotos()
        let bigFilesSize = bigFiles.reduce(Int64(0)) { $0 + $1.fileSize }
        scannedCategories.append(PhotoCategoryInfo(
            type: .bigFiles,
            count: bigFiles.count,
            size: bigFilesSize
        ))
        
        categories = scannedCategories
        totalSavings = duplicatesSize + similarSize + screenshotsSize + livePhotosSavings + burstsSize
        
        isScanning = false
    }
}

// MARK: - Photo Category Enum

enum PhotoCategory: String, CaseIterable, Hashable {
    case duplicates = "Duplicates"
    case similar = "Similar Photos"
    case screenshots = "Screenshots"
    case livePhotos = "Live Photos"
    case burst = "Burst Photos"
    case bigFiles = "Big Files"
    case highlights = "Highlights"
    
    var icon: String {
        switch self {
        case .duplicates: return "square.on.square"
        case .similar: return "square.stack.3d.down.right"
        case .screenshots: return "camera.viewfinder"
        case .livePhotos: return "livephoto"
        case .burst: return "square.stack.3d.up"
        case .bigFiles: return "doc.fill"
        case .highlights: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .duplicates: return AppColors.statusError
        case .similar: return AppColors.accentPurple
        case .screenshots: return AppColors.accentBlue
        case .livePhotos: return AppColors.statusWarning
        case .burst: return AppColors.statusSuccess
        case .bigFiles: return AppColors.accentLilac
        case .highlights: return AppColors.accentPurple
        }
    }
}

// MARK: - Photo Category Info

struct PhotoCategoryInfo: Identifiable {
    let id = UUID()
    let type: PhotoCategory
    let count: Int
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Preview

struct PhotosOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhotosOverviewView()
        }
    }
}
