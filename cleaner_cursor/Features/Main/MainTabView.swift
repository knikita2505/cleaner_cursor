import SwiftUI

// MARK: - Main Tab View
/// Главный TabView приложения согласно main_dashboard.md

struct MainTabView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @State private var dragOffset: CGFloat = 0
    
    // Tab order for swipe navigation
    private let tabOrder: [AppTab] = [.hide, .swipe, .clean, .contacts, .more]
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                // 1. Hide Tab (Secret Folder) - leftmost
                SecretFolderPlaceholder()
                    .tabItem {
                        Label(AppTab.hide.title, systemImage: AppTab.hide.icon)
                    }
                    .tag(AppTab.hide)
                
                // 2. Swipe Tab
                SwipeCleanTab()
                    .tabItem {
                        Label(AppTab.swipe.title, systemImage: AppTab.swipe.icon)
                    }
                    .tag(AppTab.swipe)
                
                // 3. Clean Tab (Dashboard) - CENTER
                DashboardView()
                    .tabItem {
                        Label(AppTab.clean.title, systemImage: AppTab.clean.icon)
                    }
                    .tag(AppTab.clean)
                
                // 4. Contacts Tab
                NavigationStack {
                    ContactsCleanerView()
                }
                    .tabItem {
                        Label(AppTab.contacts.title, systemImage: AppTab.contacts.icon)
                    }
                    .tag(AppTab.contacts)
                
                // 5. More Tab (Settings) - rightmost
                MoreView()
                    .tabItem {
                        Label(AppTab.more.title, systemImage: AppTab.more.icon)
                    }
                    .tag(AppTab.more)
            }
            .tint(AppColors.accentBlue)
            
            // Neon indicator line
            tabIndicator
        }
        .gesture(swipeGesture)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Tab Indicator
    
    private var tabIndicator: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(tabOrder.count)
            let currentIndex = tabOrder.firstIndex(of: appState.selectedTab) ?? 2
            let indicatorX = tabWidth * CGFloat(currentIndex) + tabWidth / 2
            
            // Neon horizontal line - positioned at top border of tab bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [AppColors.neonBlue, AppColors.neonPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 36, height: 3)
                .shadow(color: AppColors.neonBlue.opacity(0.8), radius: 4, x: 0, y: 0)
                .shadow(color: AppColors.neonPink.opacity(0.5), radius: 8, x: 0, y: 0)
                .position(x: indicatorX, y: 1.5)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: appState.selectedTab)
                .allowsHitTesting(false)
        }
        .frame(height: 49)
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onChanged { value in
                // Track drag for visual feedback
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                guard let currentIndex = tabOrder.firstIndex(of: appState.selectedTab) else {
                    dragOffset = 0
                    return
                }
                
                // Use velocity to make swipe feel more responsive
                let threshold: CGFloat = 50
                let shouldSwipe = abs(horizontalAmount) > threshold || abs(velocity) > 100
                
                if shouldSwipe {
                    if horizontalAmount < 0 || velocity < -100 {
                        // Swipe left - go to next tab
                        let nextIndex = min(currentIndex + 1, tabOrder.count - 1)
                        if nextIndex != currentIndex {
                            HapticManager.lightImpact()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appState.selectedTab = tabOrder[nextIndex]
                        }
                    } else if horizontalAmount > 0 || velocity > 100 {
                        // Swipe right - go to previous tab
                        let prevIndex = max(currentIndex - 1, 0)
                        if prevIndex != currentIndex {
                            HapticManager.lightImpact()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appState.selectedTab = tabOrder[prevIndex]
                        }
                    }
                }
                
                // Reset drag offset
                withAnimation(.spring(response: 0.2)) {
                    dragOffset = 0
                }
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

struct SwipeCleanTab: View {
    var body: some View {
        SwipeHubView()
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

// MARK: - More View (Tools Tab)
/// Вкладка "More" - дополнительные инструменты

struct MoreView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        NavigationStack(path: $appState.morePath) {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Premium Banner
                        if !subscriptionService.isPremium {
                            premiumBanner
                        }
                        
                        // Email Section
                        emailSection
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .withNavigationDestinations()
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
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tools")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 2) {
                // Email Cleaner
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.statusWarning.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.statusWarning)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Cleaner")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Clean spam & unsubscribe")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text("Soon")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.textTertiary.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(AppSpacing.containerPadding)
                .opacity(0.6)
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
}

// MARK: - Settings View (Sheet from Dashboard)
/// Настройки приложения

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                        #if DEBUG
                        debugSection
                        #endif
                        
                        // App Info
                        appInfo
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
    }
    
    private var premiumBanner: some View {
        Button {
            appState.presentPaywall()
            dismiss()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 2) {
                Button {
                    appState.resetOnboarding()
                    dismiss()
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
                    dismiss()
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
