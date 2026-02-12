import SwiftUI
import Photos

// MARK: - Dashboard View
/// Главный экран приложения согласно main_dashboard.md

struct DashboardView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel = DashboardViewModel.shared
    @ObservedObject private var photoService = PhotoService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject private var appState: AppState
    
    @StateObject private var healthService = DeviceHealthService.shared
    @State private var animateStorage: Bool = false
    @State private var hasAppeared: Bool = false
    @State private var showFeatureTip: Bool = false
    @State private var showPremiumPaywall: Bool = false
    @State private var showSettings: Bool = false
    @State private var widgetPage: Int = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let tipService = FeatureTipService.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $appState.dashboardPath) {
            ZStack {
                // Background
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                if !photoService.isAuthorized {
                    permissionRequiredView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Header
                            headerSection
                            
                            // Premium Banner (if not subscribed)
                            if !subscriptionManager.isPremium {
                                premiumBanner
                            }
                            
                            // Widget Carousel (Storage + Device Health)
                            widgetCarousel
                            
                            // Categories Grid
                            categoriesGrid
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, 8)
                    }
                    .fullScreenCover(isPresented: $showPremiumPaywall) {
                        PremiumPaywallView(placement: .premiumFeature)
                    }
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            SettingsView()
                                .environmentObject(appState)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .withNavigationDestinations()
            .onAppear {
                // Animate storage indicator first
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStorage = true
                }
                
                // Refresh device health
                healthService.refresh()
                
                guard !hasAppeared else {
                    // Just refresh authorization status on subsequent appears
                    photoService.checkAuthorizationStatus()
                    return
                }
                hasAppeared = true
                
                // Show feature tip on first visit (only if paywall is not showing)
                if tipService.shouldShowTip(for: .cleanPhotos) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Check if paywall is not showing before displaying tip
                        if !subscriptionManager.showPaywall {
                            showFeatureTip = true
                        }
                    }
                }
                
                Task {
                    // Check/request authorization
                    if !photoService.isAuthorized {
                        _ = await photoService.requestAuthorization()
                    }
                    
                    // Start scan if authorized
                    if photoService.isAuthorized {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.startScanIfNeeded()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFeatureTip) {
                FeatureTipView(tipData: .cleanPhotos) {
                    tipService.markTipAsShown(for: .cleanPhotos)
                    showFeatureTip = false
                    
                    // Request notification permission after onboarding
                    Task {
                        await NotificationService.shared.enableNotifications()
                    }
                }
            }
            .onChange(of: subscriptionManager.showPaywall) { _, isShowing in
                // Show feature tip after paywall is dismissed (if not shown yet)
                if !isShowing && tipService.shouldShowTip(for: .cleanPhotos) && !showFeatureTip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFeatureTip = true
                    }
                }
            }
        }
    }
    
    // MARK: - Permission Required View
    
    private var permissionRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Photos Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("To clean your photo library, we need access to your photos and videos.")
                .font(.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
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
                
                Text("Magic Swipe")
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            // Remaining items indicator (for free users)
            RemainingItemsView()
            
            // Settings button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.leading, 12)
        }
        .padding(.top, 8)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button {
            showPremiumPaywall = true
        } label: {
            HStack(spacing: 12) {
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Premium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Unlimited cleanup & all features")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(hex: "8B5CF6").opacity(0.9), Color(hex: "6D28D9").opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "A78BFA").opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    // MARK: - Widget Carousel (Storage + Device Health)
    
    private var widgetCarousel: some View {
        VStack(spacing: 8) {
            TabView(selection: $widgetPage) {
                // Page 1: Storage Summary
                storageWidget
                    .tag(0)
                
                // Page 2: Device Health
                deviceHealthWidget
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)
            
            // Custom page indicator
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(widgetPage == index ? AppColors.accentPurple : AppColors.textTertiary.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: widgetPage)
                }
            }
        }
    }
    
    private var storageWidget: some View {
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
                        miniStatItem(label: "Clutter", value: viewModel.formattedClutter, color: AppColors.neonPink)
                        miniStatItem(label: "Used", value: viewModel.formattedUsed, color: AppColors.neonBlue)
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
                
                // Used storage ring (background - neon blue)
                Circle()
                    .trim(from: 0, to: animateStorage ? viewModel.storageUsagePercentage : 0)
                    .stroke(
                        AppColors.neonBlue,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: animateStorage)
                    .animation(.easeOut(duration: 0.8), value: viewModel.storageUsagePercentage)
                
                // Clutter ring (foreground - neon pink)
                Circle()
                    .trim(from: 0, to: animateStorage ? viewModel.cleanablePercentage : 0)
                    .stroke(
                        AppColors.neonPink,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: animateStorage)
                    .animation(.easeOut(duration: 0.8), value: viewModel.cleanablePercentage)
                
                // Center - Clutter percentage
                VStack(spacing: 0) {
                    Text("\(Int(viewModel.cleanablePercentage * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Clutter")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private var deviceHealthWidget: some View {
        Button {
            appState.dashboardPath.append(DashboardDestination.deviceHealth)
        } label: {
            HStack(spacing: 16) {
                // Left side - Health Score Ring
                ZStack {
                    Circle()
                        .stroke(AppColors.progressInactive, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(healthService.healthScore) / 100.0)
                        .stroke(
                            healthScoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: healthService.healthScore)
                    
                    VStack(spacing: 0) {
                        Text("\(healthService.healthScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Health")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                // Right side - Category scores
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Health")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        healthCategoryMini(icon: "internaldrive", label: "Storage", score: healthService.storageScore)
                        healthCategoryMini(icon: "thermometer.medium", label: "Temp", score: healthService.temperatureScore)
                        healthCategoryMini(icon: "battery.75", label: "Battery", score: healthService.batteryScore)
                        healthCategoryMini(icon: "cpu", label: "Perform", score: healthService.performanceScore)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
            .padding(AppSpacing.containerPaddingLarge)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    private var healthScoreColor: Color {
        if healthService.healthScore >= 80 {
            return AppColors.statusSuccess
        } else if healthService.healthScore >= 50 {
            return AppColors.statusWarning
        } else {
            return AppColors.statusError
        }
    }
    
    private func healthCategoryMini(icon: String, label: String, score: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(categoryScoreColor(score))
            
            Text("\(label) \(score)%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private func categoryScoreColor(_ score: Int) -> Color {
        if score >= 80 {
            return AppColors.statusSuccess
        } else if score >= 50 {
            return AppColors.statusWarning
        } else {
            return AppColors.statusError
        }
    }
    
    private func miniStatItem(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(value)")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize()
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
                    CategoryCard(category: category) {
                        navigateToCategory(category)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToCategory(_ category: MediaCategory) {
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
