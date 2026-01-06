import SwiftUI
import Photos

// MARK: - Burst Photos View

struct BurstPhotosView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = BurstPhotosViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedGroupIndex: Int? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.groups.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Info Banner
                    infoBanner
                    
                    // Summary Card
                    summaryCard
                    
                    // Groups List
                    groupsList
                    
                    // Bottom Action Bar
                    if viewModel.totalToDelete > 0 {
                        bottomActionBar
                    }
                }
            }
            
            // Loading
            if viewModel.isLoading {
                loadingOverlay
            }
            
            // Processing
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .navigationTitle("Burst Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Auto-select best shots") {
                        viewModel.autoSelectBest()
                    }
                    Button("Keep only first in each") {
                        viewModel.keepOnlyFirst()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedGroupIndex != nil },
            set: { if !$0 { selectedGroupIndex = nil } }
        )) {
            if let index = selectedGroupIndex, index < viewModel.groups.count {
                BurstGroupDetailView(
                    group: $viewModel.groups[index],
                    onDone: { selectedGroupIndex = nil }
                )
            }
        }
        .alert("Delete Burst Photos?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUnselected()
                }
            }
        } message: {
            Text("Delete \(viewModel.totalToDelete) photos from burst series? This cannot be undone.")
        }
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppColors.accentLilac)
            
            Text("Keep the best shots from each burst series.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.accentLilac.opacity(0.1))
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential savings")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(viewModel.formattedTotalSavings)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.groups.count)")
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("burst series")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                statBadge(
                    count: viewModel.totalPhotos,
                    label: "Total",
                    color: AppColors.textSecondary
                )
                
                statBadge(
                    count: viewModel.totalToKeep,
                    label: "Keep",
                    color: AppColors.statusSuccess
                )
                
                statBadge(
                    count: viewModel.totalToDelete,
                    label: "Delete",
                    color: AppColors.statusError
                )
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
    }
    
    private func statBadge(count: Int, label: String, color: Color) -> some View {
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
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groups.indices, id: \.self) { index in
                    BurstGroupCard(
                        group: viewModel.groups[index],
                        onTap: { selectedGroupIndex = index }
                    )
                }
            }
            .padding(AppSpacing.screenPadding)
            .padding(.bottom, viewModel.totalToDelete > 0 ? 100 : 20)
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Delete \(viewModel.totalToDelete) photos")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Free up \(viewModel.formattedTotalSavings)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Clean Up")
                    }
                    .font(AppFonts.buttonSecondary)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
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
        EmptyStateView(
            icon: "square.stack.3d.forward.dottedline",
            iconColor: AppColors.accentLilac,
            title: "No Burst Photos",
            description: "You don't have any burst photo series.",
            buttonTitle: "Go Back"
        ) {
            dismiss()
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentLilac))
                    .scaleEffect(1.3)
                
                Text("Finding burst photos...")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(32)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                CircularProgress(
                    progress: viewModel.processingProgress,
                    lineWidth: 6,
                    size: 80,
                    showPercentage: true,
                    gradient: AppGradients.ctaGradient
                )
                
                Text("Cleaning burst photos...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Burst Group Card

struct BurstGroupCard: View {
    let group: BurstGroupModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(group.assets.count) photos in burst")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(group.formattedDate)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Keep \(group.selectedCount)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.statusSuccess)
                        }
                        
                        Text("Delete \(group.assets.count - group.selectedCount)")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.statusError)
                    }
                }
                
                // Stacked thumbnail preview
                HStack(spacing: -15) {
                    ForEach(Array(group.assets.prefix(5).enumerated()), id: \.element.id) { index, item in
                        ZStack {
                            ThumbnailView(asset: item.photoAsset)
                                .frame(width: 60, height: 60)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            item.isSelected ? AppColors.statusSuccess : AppColors.backgroundSecondary,
                                            lineWidth: 2
                                        )
                                )
                            
                            if item.isSelected {
                                Circle()
                                    .fill(AppColors.statusSuccess)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 22, y: -22)
                            }
                        }
                        .zIndex(Double(5 - index))
                    }
                    
                    if group.assets.count > 5 {
                        ZStack {
                            Circle()
                                .fill(AppColors.backgroundCard)
                                .frame(width: 60, height: 60)
                            
                            Text("+\(group.assets.count - 5)")
                                .font(AppFonts.subtitleM)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Tap hint
                HStack {
                    Spacer()
                    
                    Text("Tap to select best shots")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.accentBlue)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accentBlue)
                }
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Burst Group Detail View

struct BurstGroupDetailView: View {
    @Binding var group: BurstGroupModel
    let onDone: () -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Info bar
                    HStack {
                        Text("Tap photos to keep them")
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(group.selectedCount) selected")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.statusSuccess)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppColors.statusSuccess.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(AppSpacing.screenPadding)
                    .background(AppColors.backgroundSecondary)
                    
                    // Photos grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(group.assets.indices, id: \.self) { index in
                                BurstPhotoCell(
                                    item: group.assets[index],
                                    index: index + 1,
                                    onTap: {
                                        group.assets[index].isSelected.toggle()
                                        
                                        // Ensure at least one is selected
                                        if group.selectedCount == 0 {
                                            group.assets[index].isSelected = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(AppSpacing.screenPadding)
                    }
                    
                    // Quick actions
                    HStack(spacing: 12) {
                        Button {
                            // Select only first
                            for i in group.assets.indices {
                                group.assets[i].isSelected = i == 0
                            }
                        } label: {
                            Text("Keep First")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.accentBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.accentBlue.opacity(0.15))
                                .cornerRadius(20)
                        }
                        
                        Button {
                            // Select middle one (often best)
                            let middleIndex = group.assets.count / 2
                            for i in group.assets.indices {
                                group.assets[i].isSelected = i == middleIndex
                            }
                        } label: {
                            Text("Keep Middle")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.accentBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.accentBlue.opacity(0.15))
                                .cornerRadius(20)
                        }
                        
                        Button {
                            // Select last
                            for i in group.assets.indices {
                                group.assets[i].isSelected = i == group.assets.count - 1
                            }
                        } label: {
                            Text("Keep Last")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.accentBlue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.accentBlue.opacity(0.15))
                                .cornerRadius(20)
                        }
                        
                        Spacer()
                    }
                    .padding(AppSpacing.screenPadding)
                    .background(AppColors.backgroundSecondary)
                }
            }
            .navigationTitle("Select Best Shots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Burst Photo Cell

struct BurstPhotoCell: View {
    let item: BurstPhotoItem
    let index: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                ThumbnailView(asset: item.photoAsset)
                    .aspectRatio(1, contentMode: .fill)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                item.isSelected ? AppColors.statusSuccess : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .opacity(item.isSelected ? 1.0 : 0.5)
                
                // Index badge
                Text("#\(index)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(8)
                
                // Selection indicator
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(item.isSelected ? AppColors.statusSuccess : AppColors.borderSecondary, lineWidth: 2)
                                .frame(width: 26, height: 26)
                            
                            if item.isSelected {
                                Circle()
                                    .fill(AppColors.statusSuccess)
                                    .frame(width: 26, height: 26)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Burst Photos ViewModel

@MainActor
final class BurstPhotosViewModel: ObservableObject {
    
    @Published var groups: [BurstGroupModel] = []
    @Published var isLoading: Bool = true
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0
    
    private let photoService = PhotoService.shared
    
    var totalPhotos: Int {
        groups.reduce(0) { $0 + $1.assets.count }
    }
    
    var totalToKeep: Int {
        groups.reduce(0) { $0 + $1.selectedCount }
    }
    
    var totalToDelete: Int {
        totalPhotos - totalToKeep
    }
    
    var totalSavings: Int64 {
        groups.reduce(Int64(0)) { result, group in
            let deleteSize = group.assets
                .filter { !$0.isSelected }
                .reduce(Int64(0)) { $0 + $1.photoAsset.fileSize }
            return result + deleteSize
        }
    }
    
    var formattedTotalSavings: String {
        ByteCountFormatter.string(fromByteCount: totalSavings, countStyle: .file)
    }
    
    func load() async {
        isLoading = true
        
        let burstGroups = photoService.fetchBurstGroups()
        groups = burstGroups.map { group in
            BurstGroupModel(
                id: group.id,
                date: group.date,
                assets: group.assets.enumerated().map { index, asset in
                    BurstPhotoItem(
                        photoAsset: asset,
                        isSelected: index == 0 // Keep first by default
                    )
                }
            )
        }
        
        isLoading = false
    }
    
    func autoSelectBest() {
        // Select the best shot in each burst (middle one is often best)
        for i in groups.indices {
            let middleIndex = groups[i].assets.count / 2
            for j in groups[i].assets.indices {
                groups[i].assets[j].isSelected = j == middleIndex
            }
        }
    }
    
    func keepOnlyFirst() {
        for i in groups.indices {
            for j in groups[i].assets.indices {
                groups[i].assets[j].isSelected = j == 0
            }
        }
    }
    
    func deleteUnselected() async {
        var assetsToDelete: [PHAsset] = []
        
        for group in groups {
            for item in group.assets where !item.isSelected {
                assetsToDelete.append(item.photoAsset.asset)
            }
        }
        
        guard !assetsToDelete.isEmpty else { return }
        
        isProcessing = true
        processingProgress = 0
        
        do {
            // Calculate bytes freed
            let bytesFreed = assetsToDelete.reduce(Int64(0)) { total, asset in
                let resources = PHAssetResource.assetResources(for: asset)
                return total + (resources.first?.value(forKey: "fileSize") as? Int64 ?? 0)
            }
            
            try await photoService.deletePhotos(assetsToDelete)
            processingProgress = 1.0
            
            // Record to history
            CleaningHistoryService.shared.recordCleaning(
                type: .burstPhotos,
                itemsCount: assetsToDelete.count,
                bytesFreed: bytesFreed
            )
            
            SubscriptionService.shared.recordCleaning(count: assetsToDelete.count)
            
            // Reload
            await load()
            
        } catch {
            print("Failed to delete burst photos: \(error)")
        }
        
        isProcessing = false
    }
}

// MARK: - Burst Group Model

struct BurstGroupModel: Identifiable {
    let id: String
    let date: Date?
    var assets: [BurstPhotoItem]
    
    var selectedCount: Int {
        assets.filter { $0.isSelected }.count
    }
    
    var formattedDate: String {
        guard let date = date else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Burst Photo Item

struct BurstPhotoItem: Identifiable {
    let id: String
    let photoAsset: PhotoAsset
    var isSelected: Bool
    
    init(photoAsset: PhotoAsset, isSelected: Bool) {
        self.id = photoAsset.id
        self.photoAsset = photoAsset
        self.isSelected = isSelected
    }
}

// MARK: - Preview

struct BurstPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BurstPhotosView()
        }
    }
}

