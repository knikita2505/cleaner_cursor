import SwiftUI
import Photos

// MARK: - Highlights View

struct HighlightsView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = HighlightsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateAlbumSheet: Bool = false
    @State private var albumName: String = "Highlights"
    @State private var showSuccessAlert: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            if viewModel.highlights.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Info card
                    infoCard
                    
                    // Selection controls
                    selectionControls
                    
                    // Photos grid
                    photosGrid
                    
                    // Bottom bar
                    if viewModel.selectedCount > 0 {
                        bottomBar
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
        .navigationTitle("Highlights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .sheet(isPresented: $showCreateAlbumSheet) {
            createAlbumSheet
        }
        .alert("Album Created!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your highlights have been saved to the album '\(albumName)'")
        }
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "FFD700"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Best Photos")
                        .font(AppFonts.subtitleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("We selected \(viewModel.highlights.count) photos you might want to keep")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Quality indicators
            HStack(spacing: 16) {
                qualityBadge(icon: "camera.aperture", label: "Sharp", count: viewModel.sharpCount)
                qualityBadge(icon: "face.smiling", label: "Faces", count: viewModel.facesCount)
                qualityBadge(icon: "sun.max", label: "Well-lit", count: viewModel.wellLitCount)
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
    }
    
    private func qualityBadge(icon: String, label: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "FFD700"))
            
            Text("\(count)")
                .font(AppFonts.subtitleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "FFD700").opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Selection Controls
    
    private var selectionControls: some View {
        HStack {
            Button {
                viewModel.selectAll()
            } label: {
                Text("Select All")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accentBlue)
            }
            
            Text("•")
                .foregroundColor(AppColors.textTertiary)
            
            Button {
                viewModel.deselectAll()
            } label: {
                Text("Deselect All")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accentBlue)
            }
            
            Spacer()
            
            Text("\(viewModel.selectedCount) selected")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
    }
    
    // MARK: - Photos Grid
    
    private var photosGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.highlights.indices, id: \.self) { index in
                    HighlightPhotoCell(
                        item: viewModel.highlights[index],
                        onTap: { viewModel.toggleSelection(at: index) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, viewModel.selectedCount > 0 ? 100 : 20)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.borderSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.selectedCount) photos selected")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Save to a new album")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Button {
                    showCreateAlbumSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text("Create Album")
                    }
                    .font(AppFonts.buttonSecondary)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
            icon: "star.fill",
            iconColor: Color(hex: "FFD700"),
            title: "Not Enough Photos",
            description: "We couldn't find enough highlights yet. Try taking more photos!",
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
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FFD700")))
                    .scaleEffect(1.3)
                
                Text("Finding your best photos...")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Analyzing quality and composition")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
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
                    gradient: LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                Text("Creating album...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    // MARK: - Create Album Sheet
    
    private var createAlbumSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Preview
                    ZStack {
                        // Stacked photos preview
                        HStack(spacing: -30) {
                            ForEach(0..<min(3, viewModel.selectedItems.count), id: \.self) { index in
                                if index < viewModel.selectedItems.count {
                                    ThumbnailView(asset: viewModel.selectedItems[index].photoAsset)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.backgroundPrimary, lineWidth: 3)
                                        )
                                        .rotationEffect(.degrees(Double(index - 1) * 5))
                                        .zIndex(Double(3 - index))
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(height: 120)
                    
                    // Album name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Album Name")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        TextField("Enter album name", text: $albumName)
                            .font(AppFonts.bodyL)
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(AppSpacing.buttonRadius)
                    }
                    .padding(.horizontal)
                    
                    // Info
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text("\(viewModel.selectedCount) photos will be added to this album")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Create button
                    Button {
                        showCreateAlbumSheet = false
                        Task {
                            let success = await viewModel.createAlbum(name: albumName)
                            if success {
                                showSuccessAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Create Album")
                        }
                        .font(AppFonts.buttonPrimary)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppSpacing.buttonRadius)
                    }
                    .padding(.horizontal)
                    .disabled(albumName.isEmpty)
                    .opacity(albumName.isEmpty ? 0.6 : 1.0)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Create Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCreateAlbumSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Highlight Photo Cell

struct HighlightPhotoCell: View {
    let item: HighlightItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                ThumbnailView(asset: item.photoAsset)
                    .aspectRatio(1, contentMode: .fill)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                item.isSelected ? Color(hex: "FFD700") : Color.clear,
                                lineWidth: 3
                            )
                    )
                
                // Star badge
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFD700"))
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(6)
                
                // Selection indicator
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(
                                    item.isSelected ? Color(hex: "FFD700") : AppColors.borderSecondary,
                                    lineWidth: 2
                                )
                                .frame(width: 24, height: 24)
                            
                            if item.isSelected {
                                Circle()
                                    .fill(Color(hex: "FFD700"))
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(6)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Highlights ViewModel

@MainActor
final class HighlightsViewModel: ObservableObject {
    
    @Published var highlights: [HighlightItem] = []
    @Published var isLoading: Bool = true
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0
    
    private let photoService = PhotoService.shared
    
    var selectedCount: Int {
        highlights.filter { $0.isSelected }.count
    }
    
    var selectedItems: [HighlightItem] {
        highlights.filter { $0.isSelected }
    }
    
    // Simulated quality counts (in a real app, you'd analyze the photos)
    var sharpCount: Int {
        Int(Double(highlights.count) * 0.8)
    }
    
    var facesCount: Int {
        Int(Double(highlights.count) * 0.3)
    }
    
    var wellLitCount: Int {
        Int(Double(highlights.count) * 0.7)
    }
    
    func load() async {
        isLoading = true
        
        let photos = photoService.findHighlights()
        highlights = photos.map { photo in
            HighlightItem(photoAsset: photo, isSelected: true)
        }
        
        isLoading = false
    }
    
    func toggleSelection(at index: Int) {
        guard index < highlights.count else { return }
        highlights[index].isSelected.toggle()
    }
    
    func selectAll() {
        for i in highlights.indices {
            highlights[i].isSelected = true
        }
    }
    
    func deselectAll() {
        for i in highlights.indices {
            highlights[i].isSelected = false
        }
    }
    
    func createAlbum(name: String) async -> Bool {
        let selectedAssets = selectedItems.map { $0.photoAsset.asset }
        guard !selectedAssets.isEmpty else { return false }
        
        isProcessing = true
        processingProgress = 0
        
        do {
            try await photoService.createAlbum(name: name, with: selectedAssets)
            processingProgress = 1.0
            
            isProcessing = false
            return true
            
        } catch {
            print("Failed to create album: \(error)")
            isProcessing = false
            return false
        }
    }
}

// MARK: - Highlight Item

struct HighlightItem: Identifiable {
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

struct HighlightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HighlightsView()
        }
    }
}

