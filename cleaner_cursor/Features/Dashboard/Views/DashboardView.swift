import SwiftUI

// MARK: - Dashboard View
/// Главный экран приложения с обзором функций

struct DashboardView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var storageService = StorageService.shared
    @ObservedObject private var photoService = PhotoService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $appState.dashboardPath) {
            ScrollView {
                VStack(spacing: AppSpacing.blockSpacing) {
                    // Header
                    headerSection
                    
                    // Storage Card
                    storageCard
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Features Grid
                    featuresSection
                    
                    // Premium Banner (if not subscribed)
                    if !subscriptionService.isPremium {
                        premiumBanner
                    }
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(AppColors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cleaner")
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(icon: "gearshape.fill", color: AppColors.textSecondary) {
                        appState.selectedTab = .settings
                    }
                }
            }
            .withNavigationDestinations()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome Back")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
            
            Text("Keep Your iPhone Clean")
                .font(AppFonts.titleL)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    // MARK: - Storage Card
    
    private var storageCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Used")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                    
                    if let info = storageService.storageInfo {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(info.formattedUsed)
                                .font(AppFonts.titleM)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("of \(info.formattedTotal)")
                                .font(AppFonts.bodyM)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    } else {
                        Text("Loading...")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Circular Progress
                if let info = storageService.storageInfo {
                    CircularProgress(
                        progress: info.usagePercentage,
                        lineWidth: 6,
                        size: 56,
                        showPercentage: true,
                        gradient: AppGradients.progressGradient
                    )
                }
            }
            
            // Progress Bar
            if let info = storageService.storageInfo {
                StorageProgressBar(progress: info.usagePercentage)
            }
            
            // Stats Row
            HStack(spacing: 12) {
                storageStatItem(
                    icon: "photo.fill",
                    value: "\(photoService.totalPhotosCount)",
                    label: "Photos"
                )
                
                Divider()
                    .frame(height: 32)
                    .background(AppColors.borderSecondary)
                
                storageStatItem(
                    icon: "video.fill",
                    value: "\(VideoService.shared.totalVideosCount)",
                    label: "Videos"
                )
                
                Divider()
                    .frame(height: 32)
                    .background(AppColors.borderSecondary)
                
                if let info = storageService.storageInfo {
                    storageStatItem(
                        icon: "externaldrive.fill",
                        value: info.formattedFree,
                        label: "Free"
                    )
                }
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func storageStatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.accentBlue)
            
            Text(value)
                .font(AppFonts.subtitleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Clean")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 12) {
                quickActionButton(
                    icon: "photo.stack",
                    title: "Duplicates",
                    color: AppColors.accentBlue
                ) {
                    appState.dashboardPath.append(DashboardDestination.photosCleaner)
                }
                
                quickActionButton(
                    icon: "camera.viewfinder",
                    title: "Screenshots",
                    color: AppColors.statusSuccess
                ) {
                    appState.dashboardPath.append(DashboardDestination.photosCleaner)
                }
                
                quickActionButton(
                    icon: "livephoto",
                    title: "Live Photos",
                    color: AppColors.statusWarning
                ) {
                    appState.dashboardPath.append(DashboardDestination.photosCleaner)
                }
            }
        }
    }
    
    private func quickActionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.buttonRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Features")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 8) {
                ListCard(
                    icon: "photo.stack",
                    iconColor: AppColors.accentBlue,
                    title: "Photos Cleaner",
                    subtitle: "Remove duplicates & similar photos"
                ) {
                    appState.dashboardPath.append(DashboardDestination.photosCleaner)
                }
                
                ListCard(
                    icon: "video.fill",
                    iconColor: AppColors.accentPurple,
                    title: "Videos Cleaner",
                    subtitle: "Find large videos & compress"
                ) {
                    appState.dashboardPath.append(DashboardDestination.videosCleaner)
                }
                
                ListCard(
                    icon: "person.2.fill",
                    iconColor: AppColors.statusSuccess,
                    title: "Contacts Cleaner",
                    subtitle: "Merge duplicates & fix contacts"
                ) {
                    appState.dashboardPath.append(DashboardDestination.contactsCleaner)
                }
                
                ListCard(
                    icon: "envelope.fill",
                    iconColor: AppColors.statusWarning,
                    title: "Email Cleaner",
                    subtitle: "Clean spam & unsubscribe"
                ) {
                    appState.dashboardPath.append(DashboardDestination.emailCleaner)
                }
                
                ListCard(
                    icon: "lock.fill",
                    iconColor: AppColors.accentLilac,
                    title: "Secret Folder",
                    subtitle: "Hide private photos & videos"
                ) {
                    appState.dashboardPath.append(DashboardDestination.secretFolder)
                }
                
                ListCard(
                    icon: "battery.100",
                    iconColor: AppColors.statusSuccess,
                    title: "Battery",
                    subtitle: "Monitor & optimize battery"
                ) {
                    appState.dashboardPath.append(DashboardDestination.battery)
                }
            }
        }
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button {
            appState.presentPaywall()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppGradients.ctaGradient)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Premium")
                        .font(AppFonts.subtitleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Get unlimited access to all features")
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.containerPadding)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.accentBlue.opacity(0.15),
                        AppColors.accentPurple.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.accentBlue.opacity(0.3),
                                AppColors.accentPurple.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState.shared)
    }
}

