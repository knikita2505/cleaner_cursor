import SwiftUI
import Photos
import Contacts
import ApphudSDK
import AppsFlyerLib

@main
struct CleanerApp: App {
    
    init() {
        // 1. Initialize Apphud SDK first
        Apphud.start(apiKey: "app_nmqxh6EVfa5mV9s2P29r2CTX7CpJ9M")
        
        // 2. Configure AppsFlyer (after Apphud to link User IDs)
        AppsFlyerService.shared.configure()
    }
    
    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppState.shared)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View
/// Корневой view, управляющий отображением онбординга и основного контента

struct RootView: View {
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showSplash: Bool = true
    @State private var showPermissions: Bool = false
    @State private var permissionsCompleted: Bool = false
    @State private var hasShownOnboardingPaywall: Bool = false
    
    var body: some View {
        ZStack {
            // Main Content
            if !showSplash && !appState.showOnboarding && permissionsCompleted {
                MainTabView()
                    .transition(.opacity)
            }
            
            // Permissions Screen
            if !showSplash && !appState.showOnboarding && showPermissions && !permissionsCompleted {
                PermissionsRequestView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        permissionsCompleted = true
                        showPermissions = false
                    }
                })
                .transition(.opacity)
            }
            
            // Onboarding Overlay
            if !showSplash && appState.showOnboarding {
                OnboardingView()
                    .transition(.opacity)
            }
            
            // Splash Screen
            if showSplash {
                SplashView(onComplete: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                    
                    // Check permissions after splash
                    if !appState.showOnboarding {
                        checkPermissionsStatus()
                    }
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: appState.showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: permissionsCompleted)
        .onChange(of: appState.showOnboarding) { oldValue, newValue in
            if !newValue {
                // Onboarding completed, check if we need to show permissions
                checkPermissionsStatus()
            }
        }
        .onChange(of: permissionsCompleted) { _, completed in
            if completed && !hasShownOnboardingPaywall {
                // Show onboarding paywall after permissions completed
                showOnboardingPaywallIfNeeded()
            }
        }
        .onAppear {
            // Start background loading during splash
            startBackgroundLoading()
            
            // Check subscription status
            subscriptionManager.checkSubscriptionStatus()
        }
        .fullScreenCover(isPresented: $subscriptionManager.showPaywall) {
            // Use different paywall based on placement
            if subscriptionManager.currentPlacement == .onboarding {
                PaywallView(placement: subscriptionManager.currentPlacement)
            } else {
                PremiumPaywallView(placement: subscriptionManager.currentPlacement)
            }
        }
    }
    
    private func showOnboardingPaywallIfNeeded() {
        // Delay slightly to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !subscriptionManager.isPremium {
                hasShownOnboardingPaywall = true
                subscriptionManager.showPaywall(for: .onboarding)
            }
        }
    }
    
    private func startBackgroundLoading() {
        let photoService = PhotoService.shared
        let notificationService = NotificationService.shared
        
        Task(priority: .userInitiated) {
            // Check if we have photo access
            let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            if photoStatus == .authorized || photoStatus == .limited {
                // Start quick counts immediately
                await MainActor.run {
                    photoService.updateQuickCounts()
                }
                
                // Start heavy scans in background
                await photoService.scanDuplicatesIfNeeded()
                await photoService.scanSimilarIfNeeded()
            }
            
            // Maintain notification schedule if enabled
            await notificationService.maintainScheduleIfNeeded()
        }
    }
    
    private func checkPermissionsStatus() {
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if photoStatus == .authorized || photoStatus == .limited {
            // Already have permissions - go to dashboard
            // Scan will start automatically when DashboardView appears
            permissionsCompleted = true
        } else {
            // Need to request permissions
            showPermissions = true
        }
    }
}

// MARK: - Permissions Request View

struct PermissionsRequestView: View {
    let onComplete: () -> Void
    
    @State private var currentStep: Int = 0
    @ObservedObject private var photoService = PhotoService.shared
    @ObservedObject private var contactsService = ContactsService.shared
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress
                SegmentedProgress(
                    totalSegments: 2,
                    currentSegment: currentStep,
                    activeColor: AppColors.accentBlue,
                    inactiveColor: AppColors.progressInactive
                )
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 60)
                
                Spacer()
                
                // Content
                if currentStep == 0 {
                    permissionContent(
                        icon: "photo.fill",
                        iconColor: AppColors.accentBlue,
                        title: "Access Your Photos",
                        description: "We need access to your photos to find duplicates, similar photos, screenshots, and help you free up storage space.",
                        features: [
                            "Find duplicate photos",
                            "Detect similar images",
                            "Clean up screenshots",
                            "Remove Live Photo videos"
                        ]
                    )
                } else {
                    permissionContent(
                        icon: "person.2.fill",
                        iconColor: AppColors.statusSuccess,
                        title: "Access Your Contacts",
                        description: "We need access to your contacts to find and merge duplicates, and help you organize your address book.",
                        features: [
                            "Find duplicate contacts",
                            "Merge similar entries",
                            "Remove empty contacts",
                            "Fix phone formats"
                        ]
                    )
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    PrimaryButton(
                        title: "Continue",
                        icon: "arrow.right"
                    ) {
                        Task {
                            await requestCurrentPermission()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func permissionContent(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        features: [String]
    ) -> some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(spacing: 16) {
                Text(title)
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Features List
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.statusSuccess)
                        
                        Text(feature)
                            .font(AppFonts.bodyL)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    private func requestCurrentPermission() async {
        if currentStep == 0 {
            _ = await photoService.requestAuthorization()
            // Scan will start automatically when DashboardView appears
        } else {
            _ = await contactsService.requestAuthorization()
        }
        
        await MainActor.run {
            moveToNextStep()
        }
    }
    
    private func moveToNextStep() {
        if currentStep < 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            onComplete()
        }
    }
}

// MARK: - Preview

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState.shared)
    }
}
