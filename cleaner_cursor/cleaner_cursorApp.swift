import SwiftUI
import Photos
import Contacts

@main
struct CleanerApp: App {
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppState.shared)
                .environmentObject(SubscriptionService.shared)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View
/// Корневой view, управляющий отображением онбординга и основного контента

struct RootView: View {
    
    @EnvironmentObject private var appState: AppState
    @State private var showPermissions: Bool = false
    @State private var permissionsCompleted: Bool = false
    
    var body: some View {
        ZStack {
            // Main Content
            if !appState.showOnboarding && permissionsCompleted {
                MainTabView()
                    .transition(.opacity)
            }
            
            // Permissions Screen
            if !appState.showOnboarding && showPermissions && !permissionsCompleted {
                PermissionsRequestView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        permissionsCompleted = true
                        showPermissions = false
                    }
                })
                .transition(.opacity)
            }
            
            // Onboarding Overlay
            if appState.showOnboarding {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: permissionsCompleted)
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
        .onChange(of: appState.showOnboarding) { newValue in
            if !newValue {
                // Onboarding completed, check if we need to show permissions
                checkPermissionsStatus()
            }
        }
        .onAppear {
            // Check if we already have permissions or completed onboarding before
            if !appState.showOnboarding {
                checkPermissionsStatus()
            }
        }
    }
    
    private func checkPermissionsStatus() {
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if photoStatus == .authorized || photoStatus == .limited {
            // Already have permissions - start background scan immediately
            permissionsCompleted = true
            startBackgroundScan()
        } else {
            // Need to request permissions
            showPermissions = true
        }
    }
    
    private func startBackgroundScan() {
        // Start scan in background immediately after permissions granted
        Task {
            DashboardViewModel.shared.startScanIfNeeded()
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
                        title: "Allow Access",
                        icon: "checkmark.shield.fill"
                    ) {
                        Task {
                            await requestCurrentPermission()
                        }
                    }
                    
                    GhostButton(title: currentStep == 0 ? "Skip for Now" : "Continue") {
                        moveToNextStep()
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
            let granted = await photoService.requestAuthorization()
            if granted {
                // Start background scan immediately after photo access granted
                DashboardViewModel.shared.startScanIfNeeded()
            }
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
            .environmentObject(SubscriptionService.shared)
    }
}
