import SwiftUI
import Photos

// MARK: - Dashboard View
/// Главный экран приложения согласно main_dashboard.md

struct DashboardView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel = DashboardViewModel.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState
    
    @State private var showPaywall: Bool = false
    @State private var showSettings: Bool = false
    @State private var animateStorage: Bool = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $appState.dashboardPath) {
            ZStack {
                // Background
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Storage Summary
                        storageSummaryCard
                        
                        // Categories Grid
                        categoriesGrid
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .withNavigationDestinations()
            .onAppear {
                // Animate storage indicator first
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStorage = true
                }
                
                // Start background scan AFTER UI is rendered (не блокирует UI)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.startScanIfNeeded()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Current Time
            VStack(alignment: .leading, spacing: 2) {
                Text(currentTimeString)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text("Clean Your Phone")
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            // Start Free Trial Button
            if !subscriptionService.isPremium {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Start Free Trial")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [AppColors.statusSuccess, AppColors.statusSuccess.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: AppColors.statusSuccess.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Settings Button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(8)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.top, 8)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Storage Summary Card
    
    private var storageSummaryCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side - Text info + Stats
            VStack(alignment: .leading, spacing: 10) {
                Text("Space to clean")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                // Big number - always fits in one line
                Text(viewModel.formattedSpaceToClean)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.5), value: viewModel.spaceToClean)
                
                // Stats aligned with number
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 16) {
                        miniStatItem(label: "Clutter", value: viewModel.formattedClutter, color: Color(hex: "FF496C"))
                        miniStatItem(label: "Used", value: viewModel.formattedUsed, color: Color(hex: "87CEFA"))
                    }
                    miniStatItem(label: "Total", value: viewModel.formattedTotal, color: AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Right side - Ring Progress
            ZStack {
                Circle()
                    .stroke(AppColors.progressInactive, lineWidth: 10)
                    .frame(width: 70, height: 70)
                
                // Used storage ring
                Circle()
                    .trim(from: 0, to: animateStorage ? viewModel.storageUsagePercentage : 0)
                    .stroke(
                        Color(hex: "87CEFA"),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: animateStorage)
                    .animation(.easeOut(duration: 0.8), value: viewModel.storageUsagePercentage)
                
                // Clutter ring
                Circle()
                    .trim(from: 0, to: animateStorage ? viewModel.cleanablePercentage : 0)
                    .stroke(
                        Color(hex: "FF496C"),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: animateStorage)
                    .animation(.easeOut(duration: 0.8), value: viewModel.cleanablePercentage)
                
                // Center percentage
                Text("\(Int(viewModel.storageUsagePercentage * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private func miniStatItem(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(value)")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Categories Grid
    
    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.categories) { category in
                    CategoryCard(
                        category: category,
                        isLocked: !subscriptionService.isPremium && !subscriptionService.canCleanMore
                    ) {
                        navigateToCategory(category)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToCategory(_ category: MediaCategory) {
        // Check subscription limits
        if !subscriptionService.isPremium && !subscriptionService.canCleanMore {
            showPaywall = true
            return
        }
        
        switch category.id {
        case "duplicates":
            appState.dashboardPath.append(PhotoCategoryNav.duplicates)
        case "similar":
            appState.dashboardPath.append(PhotoCategoryNav.similar)
        case "screenshots":
            appState.dashboardPath.append(PhotoCategoryNav.screenshots)
        case "live_photos":
            appState.dashboardPath.append(PhotoCategoryNav.livePhotos)
        case "videos":
            appState.dashboardPath.append(PhotoCategoryNav.videos)
        case "short_videos":
            appState.dashboardPath.append(PhotoCategoryNav.shortVideos)
        default:
            break
        }
    }
}

// MARK: - Photo Category Navigation

enum PhotoCategoryNav: String, Hashable {
    case screenshots
    case similar
    case videos
    case shortVideos
    case livePhotos
    case duplicates
    case burst
    case bigFiles
    case highlights
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: MediaCategory
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background - full card is thumbnail or gradient
                if let thumbnail = category.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 110)
                        .clipped()
                        .opacity(isLocked ? 0.5 : 1.0)
                } else {
                    // Dark gray placeholder (одинаковый для всех при сканировании или пустых)
                    Color(white: 0.2).opacity(0.8)
                    
                    // Icon in center
                    Image(systemName: category.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Lock overlay
                if isLocked && !category.isLoading {
                    Color.black.opacity(0.5)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Text content at bottom
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if category.isLoading && category.size == 0 {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(category.formattedSize)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(14)
            }
            .frame(height: 110)
            .cornerRadius(16)
            .contentShape(Rectangle())
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .opacity(category.isEmpty && !category.isLoading ? 0.5 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .disabled(category.isEmpty && !category.isLoading)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState.shared)
    }
}
