import SwiftUI

// MARK: - Main Tab View
/// Главный TabView приложения согласно main_dashboard.md

struct MainTabView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Clean Tab (Dashboard)
            DashboardView()
                .tabItem {
                    Label(AppTab.clean.title, systemImage: AppTab.clean.icon)
                }
                .tag(AppTab.clean)
            
            // Swipe Tab
            SwipeCleanPlaceholder()
                .tabItem {
                    Label(AppTab.swipe.title, systemImage: AppTab.swipe.icon)
                }
                .tag(AppTab.swipe)
            
            // Email Tab
            EmailCleanerPlaceholder()
                .tabItem {
                    Label(AppTab.email.title, systemImage: AppTab.email.icon)
                }
                .tag(AppTab.email)
            
            // Hide Tab (Secret Folder)
            SecretFolderPlaceholder()
                .tabItem {
                    Label(AppTab.hide.title, systemImage: AppTab.hide.icon)
                }
                .tag(AppTab.hide)
            
            // More Tab (Settings)
            MoreView()
                .tabItem {
                    Label(AppTab.more.title, systemImage: AppTab.more.icon)
                }
                .tag(AppTab.more)
        }
        .tint(AppColors.accentBlue)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Tab Bar Appearance
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.backgroundSecondary)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accentBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.accentBlue),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Placeholder Views

struct SwipeCleanPlaceholder: View {
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.accentPurple.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.accentPurple)
                }
                
                Text("Swipe to Clean")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Swipe left to delete, right to keep\nComing soon...")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct EmailCleanerPlaceholder: View {
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.statusWarning.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.statusWarning)
                }
                
                Text("Email Cleaner")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Clean spam & unsubscribe\nComing soon...")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct SecretFolderPlaceholder: View {
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppColors.accentLilac.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.accentLilac)
                }
                
                Text("Secret Folder")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Hide your private photos & videos\nComing soon...")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Premium Banner
                        if !subscriptionService.isPremium {
                            premiumBanner
                        }
                        
                        // Settings List
                        settingsList
                        
                        // Debug Section
                        debugSection
                        
                        // App Info
                        appInfo
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
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
                    
                    Text("Get unlimited access")
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    private var settingsList: some View {
        VStack(spacing: 2) {
            settingsRow(icon: "bell.fill", title: "Notifications", color: AppColors.statusError)
            settingsRow(icon: "globe", title: "Language", color: AppColors.accentBlue)
            settingsRow(icon: "star.fill", title: "Rate App", color: AppColors.statusWarning)
            settingsRow(icon: "square.and.arrow.up", title: "Share App", color: AppColors.statusSuccess)
            settingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: AppColors.accentPurple)
            settingsRow(icon: "doc.text.fill", title: "Privacy Policy", color: AppColors.textTertiary)
            settingsRow(icon: "doc.text.fill", title: "Terms of Use", color: AppColors.textTertiary)
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        Button {
            // Handle tap
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, AppSpacing.containerPadding)
            .padding(.vertical, 14)
        }
    }
    
    private var debugSection: some View {
        VStack(spacing: 2) {
            Button {
                appState.resetOnboarding()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.statusWarning)
                        .frame(width: 28)
                    
                    Text("Reset Onboarding")
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.vertical, 14)
            }
            
            Button {
                appState.presentPaywall()
            } label: {
                HStack {
                    Image(systemName: "creditcard")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accentPurple)
                        .frame(width: 28)
                    
                    Text("Show Paywall")
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.vertical, 14)
            }
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private var appInfo: some View {
        VStack(spacing: 8) {
            Text("Cleaner")
                .font(AppFonts.subtitleM)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Version 1.0.0")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.top, 20)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState.shared)
    }
}
