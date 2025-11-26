import SwiftUI
import Photos

// MARK: - Dashboard View
/// Главный экран приложения согласно main_dashboard.md

struct DashboardView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState
    
    @State private var showPaywall: Bool = false
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
                
                // Scanning Overlay
                if viewModel.isScanning {
                    scanningOverlay
                }
            }
            .navigationBarHidden(true)
            .withNavigationDestinations()
            .onAppear {
                Task {
                    await viewModel.scanMedia()
                    withAnimation(.easeOut(duration: 0.5)) {
                        animateStorage = true
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
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
                    Text(viewModel.formattedSpaceToClean)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .scaleEffect(animateStorage ? 1.0 : 0.8)
                        .opacity(animateStorage ? 1.0 : 0.5)
                    
                    // Mini stats
                    VStack(alignment: .leading, spacing: 6) {
                        miniStatRow(label: "Clutter", value: viewModel.formattedClutter, color: AppColors.statusWarning)
                        miniStatRow(label: "Apps & data", value: viewModel.formattedAppsData, color: AppColors.accentBlue)
                        miniStatRow(label: "Total used", value: viewModel.formattedTotal, color: AppColors.textTertiary)
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
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.cleanablePercentage * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
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
    
    private func miniStatRow(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
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
    
    // MARK: - Scanning Overlay
    
    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated scanning indicator
                ZStack {
                    Circle()
                        .stroke(AppColors.progressInactive, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.scanProgress)
                        .stroke(
                            AppGradients.ctaGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.3), value: viewModel.scanProgress)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.accentBlue)
                }
                
                Text("Scanning your media...")
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(40)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
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
        case "screenshots":
            appState.dashboardPath.append(PhotosDestination.screenshots)
        case "similar":
            appState.dashboardPath.append(PhotosDestination.similar)
        case "videos":
            appState.dashboardPath.append(DashboardDestination.videosCleaner)
        case "live_photos":
            appState.dashboardPath.append(PhotosDestination.livePhotos)
        default:
            break
        }
    }
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
                    } else {
                        Image(systemName: category.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(category.color)
                    }
                    
                    // Lock overlay
                    if isLocked {
                        Color.black.opacity(0.4)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // Count badge
                    if category.count > 0 && !isLocked {
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
                    }
                }
                .frame(height: 100)
                .clipped()
                
                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(category.formattedSize)
                        .font(AppFonts.caption)
                        .foregroundColor(category.isEmpty ? AppColors.textTertiary : category.color)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.backgroundCard)
            }
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .opacity(category.isEmpty ? 0.6 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .disabled(category.isEmpty)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState.shared)
    }
}
