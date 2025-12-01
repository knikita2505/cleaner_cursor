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
        HStack(spacing: 16) {
            // Photos count
            VStack(alignment: .leading, spacing: 2) {
                Text("Photos")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("\(viewModel.totalPhotosCount)")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Divider()
                .frame(height: 30)
            
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
                        onToggleKeep: { assetIndex in
                            viewModel.toggleKeepPhoto(groupIndex: groupIndex, assetIndex: assetIndex)
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
    let onToggleKeep: (Int) -> Void
    
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
                        
                        // Status badges
                        HStack(spacing: 8) {
                            // Keep count
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("\(group.keepCount)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(AppColors.statusSuccess)
                            
                            // Delete count
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 10))
                                Text("\(group.deleteCount)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(AppColors.statusError)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    // Stacked preview (collapsed) with status indicators
                    if !isExpanded {
                        HStack(spacing: -8) {
                            ForEach(Array(group.assets.prefix(6).enumerated()), id: \.element.id) { index, asset in
                                ZStack(alignment: .topLeading) {
                                    DuplicateThumbnail(asset: asset, size: 56)
                                    
                                    // Status indicator
                                    if group.isKept(index) {
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
                                            group.isKept(index) ? AppColors.statusSuccess : AppColors.statusError.opacity(0.5),
                                            lineWidth: 2
                                        )
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
                            isKept: group.isKept(index),
                            onTap: { onToggleKeep(index) }
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
    
    var totalPhotosCount: Int {
        groups.reduce(0) { $0 + $1.assets.count }
    }
    
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
        groups.reduce(Int64(0)) { $0 + $1.savingsSize }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    var isAllSelected: Bool {
        // Все группы имеют только одну фото для сохранения (best)
        groups.allSatisfy { $0.keepIndices.count == 1 && $0.keepIndices.contains(0) }
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
                    keepIndices: Set([group.bestAssetIndex])  // По умолчанию сохраняем лучшую
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
                keepIndices: Set([group.bestAssetIndex])
            )
        }
        
        isLoading = false
    }
    
    func toggleKeepPhoto(groupIndex: Int, assetIndex: Int) {
        guard groupIndex < groups.count else { return }
        
        let group = groups[groupIndex]
        
        if group.keepIndices.contains(assetIndex) {
            // Нельзя убрать последнюю "Keep" фото
            if group.keepIndices.count > 1 {
                groups[groupIndex].keepIndices.remove(assetIndex)
                HapticManager.lightImpact()
            } else {
                // Показать что нельзя убрать последнюю
                HapticManager.error()
            }
        } else {
            // Добавить в Keep
            groups[groupIndex].keepIndices.insert(assetIndex)
            HapticManager.lightImpact()
        }
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            // Deselect all - оставить все фото в каждой группе
            for i in groups.indices {
                groups[i].keepIndices = Set(groups[i].assets.indices)
            }
        } else {
            // Select all - оставить только лучшую фото
            for i in groups.indices {
                groups[i].keepIndices = Set([0])
            }
        }
        HapticManager.mediumImpact()
    }
    
    func deleteSelected() async {
        var allAssetsToDelete: [PHAsset] = []
        
        for group in groups {
            for (index, asset) in group.assets.enumerated() {
                if !group.keepIndices.contains(index) {
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
    var keepIndices: Set<Int>  // Множество индексов фото для сохранения
    
    var deleteCount: Int {
        assets.count - keepIndices.count
    }
    
    var keepCount: Int {
        keepIndices.count
    }
    
    var savingsSize: Int64 {
        assets.enumerated()
            .filter { !keepIndices.contains($0.offset) }
            .reduce(Int64(0)) { $0 + $1.element.fileSize }
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        let total = assets.reduce(Int64(0)) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    func isKept(_ index: Int) -> Bool {
        keepIndices.contains(index)
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
