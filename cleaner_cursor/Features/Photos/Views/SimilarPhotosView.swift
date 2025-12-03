import SwiftUI
import Photos

// MARK: - Similar Photos View
/// Экран для очистки похожих фотографий согласно photos_similar.md

struct SimilarPhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SimilarPhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var expandedGroupId: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.groups.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Summary Bar
                    summaryBar
                    
                    // Groups List
                    groupsList
                    
                    // Bottom Bar
                    if viewModel.totalToDelete > 0 {
                        bottomBar
                    }
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                loadingOverlay
            }
            
            // Deleting Overlay
            if viewModel.isDeleting {
                deletingOverlay
            }
        }
        .navigationTitle("Similar photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isAllSelected ? "Deselect All" : "Select All") {
                    viewModel.toggleSelectAll()
                }
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.accentBlue)
            }
        }
        .alert("Delete \(viewModel.totalToDelete) photos?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.totalToDelete) photos? This action cannot be undone.")
        }
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Summary Bar
    
    private var summaryBar: some View {
        HStack(spacing: 16) {
            // Groups
            VStack(alignment: .leading, spacing: 2) {
                Text("Groups")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("\(viewModel.groups.count)")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Divider()
                .frame(height: 30)
            
            // Suggested to delete
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggested to delete")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("\(viewModel.suggestedToDelete) photos")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.statusWarning)
            }
            
            Divider()
                .frame(height: 30)
            
            // Potential savings
            VStack(alignment: .leading, spacing: 2) {
                Text("Savings")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text(viewModel.formattedTotalSavings)
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.backgroundSecondary)
    }
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groups.indices, id: \.self) { groupIndex in
                    SimilarGroupSection(
                        group: $viewModel.groups[groupIndex],
                        isExpanded: expandedGroupId == viewModel.groups[groupIndex].id,
                        onToggleExpand: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if expandedGroupId == viewModel.groups[groupIndex].id {
                                    expandedGroupId = nil
                                } else {
                                    expandedGroupId = viewModel.groups[groupIndex].id
                                }
                            }
                        },
                        onToggleDelete: { assetIndex in
                            viewModel.toggleDelete(groupIndex: groupIndex, assetIndex: assetIndex)
                        }
                    )
                }
            }
            .padding(AppSpacing.screenPadding)
            .padding(.bottom, viewModel.totalToDelete > 0 ? 100 : 20)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalToDelete) photos selected")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(viewModel.formattedSelectedSize) to clean")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete selected")
                        .font(AppFonts.buttonPrimary)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(AppColors.statusError)
                        .cornerRadius(AppSpacing.buttonRadius)
                }
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.backgroundSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.statusSuccess)
            
            VStack(spacing: 8) {
                Text("No similar photos found")
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your photo library looks great!")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Go back to Dashboard")
                    .font(AppFonts.buttonSecondary)
                    .foregroundColor(AppColors.accentBlue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.accentBlue.opacity(0.15))
                    .cornerRadius(AppSpacing.buttonRadius)
            }
        }
        .padding(AppSpacing.screenPadding)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentPurple))
                    .scaleEffect(1.3)
                
                Text("Finding similar photos...")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(32)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    // MARK: - Deleting Overlay
    
    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                CircularProgress(
                    progress: viewModel.deleteProgress,
                    lineWidth: 6,
                    size: 80,
                    showPercentage: true,
                    gradient: AppGradients.ctaGradient
                )
                
                Text("Deleting photos...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Similar Group Section

struct SimilarGroupSection: View {
    @Binding var group: SimilarGroupItem
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleDelete: (Int) -> Void
    
    private let expandedColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                VStack(alignment: .leading, spacing: 12) {
                    // Info row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(group.assets.count) similar photos")
                                    .font(AppFonts.subtitleM)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if group.isBurst {
                                    Text("BURST")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(AppColors.accentPurple)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(group.dateRange)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(group.deleteCount) to delete")
                                .font(AppFonts.caption)
                                .foregroundColor(group.deleteCount > 0 ? AppColors.statusError : AppColors.textTertiary)
                            
                            Text("Save \(group.formattedSavings)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.statusSuccess)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.leading, 8)
                    }
                    
                    // Preview (collapsed) with status indicators
                    if !isExpanded {
                        HStack(spacing: -8) {
                            ForEach(Array(group.assets.prefix(6).enumerated()), id: \.element.id) { index, asset in
                                ZStack(alignment: .topLeading) {
                                    SimilarThumbnail(asset: asset.photoAsset, size: 56)
                                    
                                    // Status indicator
                                    if !asset.isMarkedForDeletion {
                                        // Green checkmark for Keep
                                        Circle()
                                            .fill(AppColors.statusSuccess)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: -2, y: -2)
                                    } else {
                                        // Red X for Delete
                                        Circle()
                                            .fill(AppColors.statusError)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: -2, y: -2)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            asset.isMarkedForDeletion ? AppColors.statusError.opacity(0.5) : AppColors.statusSuccess,
                                            lineWidth: 2
                                        )
                                )
                                .zIndex(Double(6 - index))
                            }
                            
                            if group.assets.count > 6 {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.backgroundCard)
                                        .frame(width: 48, height: 48)
                                    
                                    Text("+\(group.assets.count - 6)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(AppSpacing.containerPadding)
            
            // Expanded grid
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppSpacing.containerPadding)
                
                LazyVGrid(columns: expandedColumns, spacing: 8) {
                    ForEach(group.assets.indices, id: \.self) { index in
                        SimilarPhotoItem(
                            asset: group.assets[index],
                            isBest: index == group.bestAssetIndex,
                            onTap: { onToggleDelete(index) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.vertical, 12)
            }
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
}

// MARK: - Similar Photo Item

struct SimilarPhotoItem: View {
    let asset: SimilarAssetItem
    let isBest: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    SimilarThumbnail(asset: asset.photoAsset, size: geometry.size.width)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    asset.isMarkedForDeletion ? AppColors.statusError : 
                                        (isBest ? AppColors.statusSuccess : Color.clear),
                                    lineWidth: 2
                                )
                        )
                        .opacity(asset.isMarkedForDeletion ? 0.6 : 1.0)
                    
                    // Badges
                    if isBest && !asset.isMarkedForDeletion {
                        Text("Best")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.statusSuccess)
                            .cornerRadius(4)
                            .padding(4)
                    } else if asset.isMarkedForDeletion {
                        ZStack {
                            Circle()
                                .fill(AppColors.statusError)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(4)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Similar Thumbnail

struct SimilarThumbnail: View {
    let asset: PhotoAsset
    let size: CGFloat?
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(AppColors.backgroundCard)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                            .scaleEffect(0.5)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .cornerRadius(8)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        let requestSize = size ?? 200
        PhotoService.shared.loadThumbnail(
            for: asset.asset,
            size: CGSize(width: requestSize, height: requestSize)
        ) { img in
            self.image = img
        }
    }
}

// MARK: - Similar Photos ViewModel

@MainActor
final class SimilarPhotosViewModel: ObservableObject {
    
    @Published var groups: [SimilarGroupItem] = []
    @Published var isLoading: Bool = true
    @Published var isDeleting: Bool = false
    @Published var deleteProgress: Double = 0
    
    private let photoService = PhotoService.shared
    
    // MARK: - Computed Properties
    
    var totalToDelete: Int {
        groups.reduce(0) { $0 + $1.deleteCount }
    }
    
    var suggestedToDelete: Int {
        groups.reduce(0) { result, group in
            result + max(0, group.assets.count - 1)
        }
    }
    
    var totalSavings: Int64 {
        groups.reduce(Int64(0)) { $0 + $1.savingsSize }
    }
    
    var formattedTotalSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavings, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        groups.reduce(Int64(0)) { result, group in
            let deleteSize = group.assets
                .filter { $0.isMarkedForDeletion }
                .reduce(Int64(0)) { $0 + $1.photoAsset.fileSize }
            return result + deleteSize
        }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    var isAllSelected: Bool {
        // Все группы имеют выбранными все фото кроме лучшей (bestAssetIndex)
        groups.allSatisfy { group in
            let expectedDeleteCount = group.assets.count - 1
            return group.deleteCount == expectedDeleteCount
        }
    }
    
    // MARK: - Actions
    
    func load() async {
        isLoading = true
        
        // Use cached data if available
        if photoService.similarScanned {
            groups = photoService.cachedSimilarPhotos.map { group in
                let items = group.assets.enumerated().map { index, asset in
                    SimilarAssetItem(
                        photoAsset: asset,
                        isMarkedForDeletion: index != group.bestAssetIndex
                    )
                }
                
                return SimilarGroupItem(
                    id: group.id,
                    assets: items,
                    bestAssetIndex: group.bestAssetIndex,
                    isBurst: group.isBurstGroup
                )
            }
            isLoading = false
            return
        }
        
        // If not scanned yet, trigger scan
        await photoService.scanSimilarIfNeeded()
        
        groups = photoService.cachedSimilarPhotos.map { group in
            let items = group.assets.enumerated().map { index, asset in
                SimilarAssetItem(
                    photoAsset: asset,
                    isMarkedForDeletion: index != group.bestAssetIndex
                )
            }
            
            return SimilarGroupItem(
                id: group.id,
                assets: items,
                bestAssetIndex: group.bestAssetIndex,
                isBurst: group.isBurstGroup
            )
        }
        
        isLoading = false
    }
    
    func toggleDelete(groupIndex: Int, assetIndex: Int) {
        guard groupIndex < groups.count,
              assetIndex < groups[groupIndex].assets.count else { return }
        
        // Нельзя удалить все фото - минимум 1 должно остаться
        let currentDeleteCount = groups[groupIndex].deleteCount
        let isCurrentlyMarked = groups[groupIndex].assets[assetIndex].isMarkedForDeletion
        
        if !isCurrentlyMarked && currentDeleteCount >= groups[groupIndex].assets.count - 1 {
            // Пытаемся пометить последнее фото - запрещено
            HapticManager.error()
            return
        }
        
        groups[groupIndex].assets[assetIndex].isMarkedForDeletion.toggle()
        HapticManager.lightImpact()
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            // Deselect all - снять отметку удаления со всех фото
            for i in groups.indices {
                for j in groups[i].assets.indices {
                    groups[i].assets[j].isMarkedForDeletion = false
                }
            }
        } else {
            // Select all - отметить все кроме лучшей для удаления
            for i in groups.indices {
                for j in groups[i].assets.indices {
                    groups[i].assets[j].isMarkedForDeletion = j != groups[i].bestAssetIndex
                }
            }
        }
        HapticManager.mediumImpact()
    }
    
    func deleteSelected() async {
        var allAssetsToDelete: [PHAsset] = []
        
        for group in groups {
            for asset in group.assets where asset.isMarkedForDeletion {
                allAssetsToDelete.append(asset.photoAsset.asset)
            }
        }
        
        guard !allAssetsToDelete.isEmpty else { return }
        
        isDeleting = true
        deleteProgress = 0
        
        do {
            let batchSize = 20
            var deletedCount = 0
            
            for i in stride(from: 0, to: allAssetsToDelete.count, by: batchSize) {
                let end = min(i + batchSize, allAssetsToDelete.count)
                let batch = Array(allAssetsToDelete[i..<end])
                
                try await photoService.deletePhotos(batch)
                
                deletedCount = end
                deleteProgress = Double(deletedCount) / Double(allAssetsToDelete.count)
            }
            
            HapticManager.success()
            SubscriptionService.shared.recordCleaning(count: allAssetsToDelete.count)
            
            await load()
            
        } catch {
            print("Failed to delete similar photos: \(error)")
            HapticManager.error()
        }
        
        isDeleting = false
    }
}

// MARK: - Similar Group Item Model

struct SimilarGroupItem: Identifiable {
    let id: String
    var assets: [SimilarAssetItem]
    var bestAssetIndex: Int
    var isBurst: Bool
    
    var deleteCount: Int {
        assets.filter { $0.isMarkedForDeletion }.count
    }
    
    var savingsSize: Int64 {
        assets.filter { $0.isMarkedForDeletion }
            .reduce(Int64(0)) { $0 + $1.photoAsset.fileSize }
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var dateRange: String {
        let dates = assets.compactMap { $0.photoAsset.creationDate }
        guard let first = dates.first else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: first)
    }
}

// MARK: - Similar Asset Item Model

struct SimilarAssetItem: Identifiable {
    let id: String
    let photoAsset: PhotoAsset
    var isMarkedForDeletion: Bool
    
    init(photoAsset: PhotoAsset, isMarkedForDeletion: Bool) {
        self.id = photoAsset.id
        self.photoAsset = photoAsset
        self.isMarkedForDeletion = isMarkedForDeletion
    }
}

// MARK: - Preview

struct SimilarPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SimilarPhotosView()
        }
    }
}
