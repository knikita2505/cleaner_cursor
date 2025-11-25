import SwiftUI

// MARK: - Main Tab View
/// Главный TabView приложения

struct MainTabView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
                }
                .tag(AppTab.dashboard)
            
            // Photos Tab
            PhotosOverviewPlaceholder()
                .tabItem {
                    Label(AppTab.photos.title, systemImage: AppTab.photos.icon)
                }
                .tag(AppTab.photos)
            
            // Storage Tab
            StorageOverviewPlaceholder()
                .tabItem {
                    Label(AppTab.storage.title, systemImage: AppTab.storage.icon)
                }
                .tag(AppTab.storage)
            
            // Settings Tab
            SettingsPlaceholder()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
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
            .foregroundColor: UIColor(AppColors.textTertiary)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accentBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.accentBlue)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Placeholder Views

struct PhotosOverviewPlaceholder: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.accentBlue.opacity(0.5))
                    
                    Text("Photos Cleaner")
                        .font(AppFonts.titleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Coming soon...")
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StorageOverviewPlaceholder: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.accentPurple.opacity(0.5))
                    
                    Text("Storage Overview")
                        .font(AppFonts.titleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Coming soon...")
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .navigationTitle("Storage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsPlaceholder: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.textTertiary.opacity(0.5))
                    
                    Text("Settings")
                        .font(AppFonts.titleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: 12) {
                        SecondaryButton(title: "Reset Onboarding") {
                            appState.resetOnboarding()
                        }
                        
                        GhostButton(title: "Show Paywall") {
                            appState.presentPaywall()
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState.shared)
    }
}

