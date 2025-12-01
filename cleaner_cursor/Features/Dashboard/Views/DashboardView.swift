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
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                // Left side - Text info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Space to clean")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    // Big number with animation
                    if viewModel.isScanning && viewModel.spaceToClean == 0 {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                            Text("Scanning...")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(height: 50)
                    } else {
                        Text(viewModel.formattedSpaceToClean)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.5), value: viewModel.spaceToClean)
                    }
                    
                    // Mini stats
                    VStack(alignment: .leading, spacing: 6) {
                        miniStatRow(label: "Clutter", value: viewModel.formattedClutter, color: AppColors.statusWarning, isLoading: viewModel.isScanning && viewModel.clutterSize == 0)
                        miniStatRow(label: "Apps & data", value: viewModel.formattedAppsData, color: AppColors.accentBlue, isLoading: viewModel.isScanning && viewModel.appsDataSize == 0)
                        miniStatRow(label: "Total used", value: viewModel.formattedTotal, color: AppColors.textTertiary, isLoading: viewModel.totalStorageUsed == 0)
                    }
                }
                
                Spacer()
                
                // Right side - Circular Progress
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(AppColors.progressInactive, lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: animateStorage ? viewModel.cleanablePercentage : 0)
                        .stroke(
                            AngularGradient(
                                colors: [AppColors.accentBlue, AppColors.accentPurple, AppColors.accentBlue],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: animateStorage)
                        .animation(.easeOut(duration: 0.8), value: viewModel.cleanablePercentage)
                    
                    // Center text
                    VStack(spacing: 2) {
                        if viewModel.isScanning && viewModel.spaceToClean == 0 {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                                .scaleEffect(0.8)
                        } else {
                            Text("\(Int(viewModel.cleanablePercentage * 100))%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.5), value: viewModel.cleanablePercentage)
                        }
                        
                        Text("clutter")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private func miniStatRow(label: String, value: String, color: Color, isLoading: Bool = false) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
                    .scaleEffect(0.4)
                    .frame(width: 16, height: 16)
            } else {
                Text(value)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
    }
    
    // MARK: - Categories Grid
    
    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Categories")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Scanning indicator
                if viewModel.isScanning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                            .scaleEffect(0.7)
                        
                        Text(viewModel.scanProgress)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textTertiary)
                            .lineLimit(1)
                    }
                } else {
                    // Refresh button
                    Button {
                        viewModel.forceRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            
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
        case "screen_recordings":
            appState.dashboardPath.append(PhotoCategoryNav.screenRecordings)
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
    case screenRecordings
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
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail area
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            category.color.opacity(0.3),
                            category.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Thumbnail or icon
                    if let thumbnail = category.thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(isLocked ? 0.5 : 1.0)
                            .transition(.opacity)
                    } else {
                        // Icon or loading
                        if category.isLoading {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: category.color))
                                    .scaleEffect(0.8)
                            }
                        } else {
                            Image(systemName: category.icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(category.color)
                        }
                    }
                    
                    // Lock overlay
                    if isLocked && !category.isLoading {
                        Color.black.opacity(0.4)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // Count badge
                    if category.count > 0 && !isLocked && !category.isLoading {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Text("\(category.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(category.color)
                                    .cornerRadius(10)
                                    .padding(8)
                            }
                            Spacer()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 100)
                .clipped()
                .animation(.easeInOut(duration: 0.3), value: category.thumbnail != nil)
                
                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    if category.isLoading && category.size == 0 {
                        HStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: category.color))
                                .scaleEffect(0.5)
                            Text("Scanning...")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    } else {
                        Text(category.formattedSize)
                            .font(AppFonts.caption)
                            .foregroundColor(category.isEmpty ? AppColors.textTertiary : category.color)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.backgroundCard)
                .animation(.easeInOut(duration: 0.3), value: category.isLoading)
            }
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .opacity(category.isEmpty && !category.isLoading ? 0.6 : 1.0)
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
