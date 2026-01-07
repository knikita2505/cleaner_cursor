import SwiftUI
import Photos

// Используем PhotoSortOption из SimilarPhotosView (глобальный enum)

// MARK: - Duplicates View
/// Экран для поиска и удаления дубликатов согласно photos_duplicates.md

struct DuplicatesView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = DuplicatesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var expandedGroupId: String? = nil
    @State private var sortOption: PhotoSortOption = .recent
    @State private var showSortPicker: Bool = false
    
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
        .confirmationDialog("Sort by", isPresented: $showSortPicker, titleVisibility: .visible) {
            ForEach(PhotoSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    sortOption = option
                }
            }
            Button("Cancel", role: .cancel) {}
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
                
                Text("\(sortedGroups.count)")
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
            
            // Sort button
            Button {
                showSortPicker = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.backgroundSecondary)
    }
    
    private var sortedGroups: [DuplicateGroupItem] {
        switch sortOption {
        case .recent:
            return viewModel.groups.sorted { ($0.assets.first?.creationDate ?? .distantPast) > ($1.assets.first?.creationDate ?? .distantPast) }
        case .oldest:
            return viewModel.groups.sorted { ($0.assets.first?.creationDate ?? .distantPast) < ($1.assets.first?.creationDate ?? .distantPast) }
        case .largest:
            return viewModel.groups.sorted { $0.totalSize > $1.totalSize }
        }
    }
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedGroups) { group in
                    if let groupIndex = viewModel.groups.firstIndex(where: { $0.id == group.id }) {
                        DuplicateGroupSection(
                            group: $viewModel.groups[groupIndex],
                            isExpanded: expandedGroupId == group.id,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    if expandedGroupId == group.id {
                                        expandedGroupId = nil
                                    } else {
                                        expandedGroupId = group.id
                                    }
                                }
                            },
                            onToggleKeep: { assetIndex in
                                viewModel.toggleKeepPhoto(groupIndex: groupIndex, assetIndex: assetIndex)
                            }
                        )
                    }
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
                    Text("\(viewModel.totalToDelete) selected")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(viewModel.formattedSelectedSize)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppColors.statusError)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, 10)
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
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onToggleExpand) {
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
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("\(group.keepCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppColors.statusSuccess)
                        
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
            }
            .buttonStyle(.plain)
            .padding(AppSpacing.containerPadding)
            
            // Preview (collapsed) - horizontal carousel with tap to toggle
            if !isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(group.assets.enumerated()), id: \.element.id) { index, asset in
                            Button {
                                onToggleKeep(index)
                            } label: {
                                ZStack {
                                    DuplicateThumbnail(asset: asset, size: 130)
                                    
                                    // Top badges
                                    VStack {
                                        HStack {
                                            // Status indicator - only show trash for items to delete
                                            if !group.isKept(index) {
                                                Circle()
                                                    .fill(AppColors.statusError)
                                                    .frame(width: 26, height: 26)
                                                    .overlay(
                                                        Image(systemName: "trash.fill")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(.white)
                                                    )
                                            }
                                            
                                            Spacer()
                                            
                                            // Favorite badge
                                            if asset.isFavorite {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                                    .padding(3)
                                                    .background(Color.white.opacity(0.9))
                                                    .clipShape(Circle())
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(6)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            group.isKept(index) ? AppColors.statusSuccess : AppColors.statusError.opacity(0.5),
                                            lineWidth: 3
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.containerPadding)
                    .padding(.bottom, 12)
                }
            }
            
            // Expanded - vertical grid
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppSpacing.containerPadding)
                
                LazyVGrid(columns: expandedColumns, spacing: 10) {
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
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isKept ? AppColors.statusSuccess : AppColors.statusError.opacity(0.5), lineWidth: 3)
                    
                    // Top badges
                    HStack {
                        // Show trash icon only for photos marked for deletion
                        if !isKept {
                            ZStack {
                                Circle()
                                    .fill(AppColors.statusError)
                                    .frame(width: 26, height: 26)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Favorite badge
                        if asset.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(6)
                }
                .cornerRadius(12)
                .contentShape(Rectangle())
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
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
        .cornerRadius(10)
        .onAppear {
            loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() {
        let targetSize = CGFloat(max(size ?? 110, 110) * 2) // Retina
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
        // Проверяем что все НЕ-избранные и НЕ-лучшие (индекс 0) фото НЕ в keepIndices (т.е. выбраны для удаления)
        groups.allSatisfy { group in
            for (index, asset) in group.assets.enumerated() {
                let isBest = index == 0
                let isFavorite = asset.isFavorite
                let isKept = group.keepIndices.contains(index)
                
                // Если фото НЕ лучшее и НЕ избранное, оно НЕ должно быть в keepIndices
                if !isBest && !isFavorite && isKept {
                    return false
                }
            }
            return true
        }
    }
    
    // MARK: - Actions
    
    func load() async {
        isLoading = true
        
        // Use cached data if available
        if photoService.duplicatesScanned {
            groups = photoService.cachedDuplicates.map { group in
                // Сохраняем лучшую + все избранные
                var keepSet = Set([group.bestAssetIndex])
                for (index, asset) in group.assets.enumerated() {
                    if asset.isFavorite {
                        keepSet.insert(index)
                    }
                }
                return DuplicateGroupItem(
                    id: group.id,
                    assets: group.assets,
                    keepIndices: keepSet
                )
            }
            isLoading = false
            return
        }
        
        // If not scanned yet, trigger scan (will update via cache)
        await photoService.scanDuplicatesIfNeeded()
        
        groups = photoService.cachedDuplicates.map { group in
            // Сохраняем лучшую + все избранные
            var keepSet = Set([group.bestAssetIndex])
            for (index, asset) in group.assets.enumerated() {
                if asset.isFavorite {
                    keepSet.insert(index)
                }
            }
            return DuplicateGroupItem(
                id: group.id,
                assets: group.assets,
                keepIndices: keepSet
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
        let selectAll = !isAllSelected
        let currentGroups = groups
        
        // Выполняем в фоне чтобы не блокировать UI
        Task.detached(priority: .userInitiated) {
            var result: [DuplicateGroupItem] = []
            
            for var group in currentGroups {
                if selectAll {
                    // Оставляем лучшую (индекс 0) + все избранные
                    var keepSet = Set([0])
                    for (index, asset) in group.assets.enumerated() {
                        if asset.isFavorite {
                            keepSet.insert(index)
                        }
                    }
                    group.keepIndices = keepSet
                } else {
                    group.keepIndices = Set(group.assets.indices)
                }
                result.append(group)
            }
            
            await MainActor.run { [result] in
                self.groups = result
                HapticManager.mediumImpact()
            }
        }
    }
    
    func deleteSelected() async {
        var assetsToDeleteIds: Set<String> = []
        var allAssetsToDelete: [PHAsset] = []
        
        for group in groups {
            for (index, asset) in group.assets.enumerated() {
                if !group.keepIndices.contains(index) {
                    assetsToDeleteIds.insert(asset.id)
                    allAssetsToDelete.append(asset.asset)
                }
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
            
            // Calculate bytes freed
            let bytesFreed = allAssetsToDelete.reduce(Int64(0)) { total, asset in
                let resources = PHAssetResource.assetResources(for: asset)
                return total + (resources.first?.value(forKey: "fileSize") as? Int64 ?? 0)
            }
            
            // Record to history
            CleaningHistoryService.shared.recordCleaning(
                type: .duplicates,
                itemsCount: allAssetsToDelete.count,
                bytesFreed: bytesFreed
            )
            
            HapticManager.success()
            SubscriptionService.shared.recordCleaning(count: allAssetsToDelete.count)
            
            // Сбрасываем прогресс бар
            isDeleting = false
            deleteProgress = 0
            
            // Удаляем фото из локального списка БЕЗ перезагрузки
            removeDeletedPhotos(ids: assetsToDeleteIds)
            
        } catch {
            print("Failed to delete duplicates: \(error)")
            HapticManager.error()
            isDeleting = false
            deleteProgress = 0
        }
    }
    
    private func removeDeletedPhotos(ids: Set<String>) {
        // Создаём новый список групп без удалённых фото
        var updatedGroups: [DuplicateGroupItem] = []
        
        for group in groups {
            // Фильтруем только оставшиеся (keep) фото
            let remainingAssets = group.assets.enumerated()
                .filter { group.keepIndices.contains($0.offset) }
                .map { $0.element }
            
            // Пропускаем группы где осталось <= 1 фото
            guard remainingAssets.count > 1 else { continue }
            
            // Создаём новую группу где все фото отмечены для сохранения
            var newGroup = DuplicateGroupItem(
                id: group.id,
                assets: remainingAssets,
                keepIndices: Set(remainingAssets.indices)
            )
            // По умолчанию предлагаем оставить первую
            newGroup.keepIndices = Set([0])
            
            updatedGroups.append(newGroup)
        }
        
        groups = updatedGroups
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
    
    var totalSize: Int64 {
        assets.reduce(Int64(0)) { $0 + $1.fileSize }
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: savingsSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
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
