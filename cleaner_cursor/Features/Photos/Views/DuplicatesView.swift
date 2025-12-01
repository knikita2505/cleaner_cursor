import SwiftUI
import Photos

// MARK: - Duplicates View
/// Экран для поиска и удаления дубликатов согласно photos_duplicates.md

struct DuplicatesView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = DuplicatesViewModel()
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
                    
                    // Bottom Bar (CTA)
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
        .navigationTitle("Duplicate photos")
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
        HStack(spacing: 20) {
            // Groups count
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
            
            // Potential savings
            VStack(alignment: .leading, spacing: 2) {
                Text("Potential savings")
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
                    DuplicateGroupSection(
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
                        onKeepPhoto: { assetIndex in
                            viewModel.setKeepPhoto(groupIndex: groupIndex, assetIndex: assetIndex)
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
                Text("No duplicate photos found")
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your photo library is clean!")
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
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.3)
                
                Text("Finding duplicates...")
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

// MARK: - Duplicate Group Section

struct DuplicateGroupSection: View {
    @Binding var group: DuplicateGroupItem
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onKeepPhoto: (Int) -> Void
    
    private let expandedColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onToggleExpand) {
                VStack(alignment: .leading, spacing: 12) {
                    // Info row
                    HStack {
                        Text("\(group.assets.count) photos")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text(group.formattedTotalSize)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        // Auto-selected badge
                        Text("Auto-selected: \(group.deleteCount)")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.accentBlue.opacity(0.15))
                            .cornerRadius(8)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    // Stacked preview (collapsed)
                    if !isExpanded {
                        HStack(spacing: -12) {
                            ForEach(Array(group.assets.prefix(6).enumerated()), id: \.element.id) { index, asset in
                                DuplicateThumbnail(asset: asset, size: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.backgroundSecondary, lineWidth: 2)
                                    )
                                    .zIndex(Double(6 - index))
                            }
                            
                            if group.assets.count > 6 {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.backgroundCard)
                                        .frame(width: 56, height: 56)
                                    
                                    Text("+\(group.assets.count - 6)")
                                        .font(AppFonts.caption)
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
                        DuplicatePhotoItem(
                            asset: group.assets[index],
                            isKept: group.keepIndex == index,
                            onTap: { onKeepPhoto(index) }
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

// MARK: - Duplicate Photo Item (in expanded grid)

struct DuplicatePhotoItem: View {
    let asset: PhotoAsset
    let isKept: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Thumbnail
                    DuplicateThumbnail(asset: asset, size: geometry.size.width)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                    
                    // Border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isKept ? AppColors.statusSuccess : AppColors.statusError.opacity(0.5), lineWidth: 2)
                    
                    // Badge
                    if isKept {
                        Text("Keep")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.statusSuccess)
                            .cornerRadius(4)
                            .padding(6)
                    } else {
                        // Delete checkbox
                        ZStack {
                            Circle()
                                .fill(AppColors.statusError)
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(6)
                    }
                }
                .cornerRadius(8)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duplicate Thumbnail

struct DuplicateThumbnail: View {
    let asset: PhotoAsset
    let size: CGFloat?
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Rectangle()
                    .fill(AppColors.backgroundCard)
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textTertiary))
                            .scaleEffect(0.6)
                    )
            }
        }
        .cornerRadius(8)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        let targetSize = CGFloat(max(size ?? 100, 100) * 2) // Retina
        PhotoService.shared.loadThumbnail(
            for: asset.asset,
            size: CGSize(width: targetSize, height: targetSize)
        ) { img in
            self.image = img
        }
    }
}

// MARK: - Duplicates ViewModel

@MainActor
final class DuplicatesViewModel: ObservableObject {
    
    @Published var groups: [DuplicateGroupItem] = []
    @Published var isLoading: Bool = true
    @Published var isDeleting: Bool = false
    @Published var deleteProgress: Double = 0
    
    private let photoService = PhotoService.shared
    
    // MARK: - Computed Properties
    
    var totalToDelete: Int {
        groups.reduce(0) { $0 + $1.deleteCount }
    }
    
    var totalSavings: Int64 {
        groups.reduce(Int64(0)) { $0 + $1.savingsSize }
    }
    
    var formattedTotalSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavings, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        groups.reduce(Int64(0)) { result, group in
            let deleteSize = group.assets.enumerated()
                .filter { $0.offset != group.keepIndex }
                .reduce(Int64(0)) { $0 + $1.element.fileSize }
            return result + deleteSize
        }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    var isAllSelected: Bool {
        // All groups have keepIndex = 0 (default auto-selection)
        groups.allSatisfy { $0.keepIndex == 0 }
    }
    
    // MARK: - Actions
    
    func load() async {
        isLoading = true
        
        // Use cached data if available
        if photoService.duplicatesScanned {
            groups = photoService.cachedDuplicates.map { group in
                DuplicateGroupItem(
                    id: group.id,
                    assets: group.assets,
                    keepIndex: group.bestAssetIndex
                )
            }
            isLoading = false
            return
        }
        
        // If not scanned yet, trigger scan (will update via cache)
        await photoService.scanDuplicatesIfNeeded()
        
        groups = photoService.cachedDuplicates.map { group in
            DuplicateGroupItem(
                id: group.id,
                assets: group.assets,
                keepIndex: group.bestAssetIndex
            )
        }
        
        isLoading = false
    }
    
    func setKeepPhoto(groupIndex: Int, assetIndex: Int) {
        guard groupIndex < groups.count else { return }
        groups[groupIndex].keepIndex = assetIndex
        HapticManager.lightImpact()
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            // Deselect all - keep last photo in each group
            for i in groups.indices {
                groups[i].keepIndex = groups[i].assets.count - 1
            }
        } else {
            // Select all - reset to auto (best photo)
            for i in groups.indices {
                groups[i].keepIndex = 0
            }
        }
        HapticManager.mediumImpact()
    }
    
    func deleteSelected() async {
        var allAssetsToDelete: [PHAsset] = []
        
        for group in groups {
            for (index, asset) in group.assets.enumerated() {
                if index != group.keepIndex {
                    allAssetsToDelete.append(asset.asset)
                }
            }
        }
        
        guard !allAssetsToDelete.isEmpty else { return }
        
        isDeleting = true
        deleteProgress = 0
        
        do {
            // Delete in batches
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
            
            // Reload
            await load()
            
        } catch {
            print("Failed to delete duplicates: \(error)")
            HapticManager.error()
        }
        
        isDeleting = false
    }
}

// MARK: - Duplicate Group Item Model

struct DuplicateGroupItem: Identifiable {
    let id: String
    var assets: [PhotoAsset]
    var keepIndex: Int
    
    var deleteCount: Int {
        assets.count - 1
    }
    
    var savingsSize: Int64 {
        assets.enumerated()
            .filter { $0.offset != keepIndex }
            .reduce(Int64(0)) { $0 + $1.element.fileSize }
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        let total = assets.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

// MARK: - Preview

struct DuplicatesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DuplicatesView()
        }
    }
}
