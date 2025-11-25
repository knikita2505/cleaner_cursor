import SwiftUI

// MARK: - Onboarding View
/// Экран онбординга с пагинацией

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @State private var currentPage: Int = 0
    
    private let totalPages = 4
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            AuroraBackground(animated: true)
            
            VStack(spacing: 0) {
                // Progress Indicator
                SegmentedProgress(
                    totalSegments: totalPages,
                    currentSegment: currentPage,
                    activeColor: .white,
                    inactiveColor: .white.opacity(0.3)
                )
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 20)
                
                // Skip Button
                HStack {
                    Spacer()
                    
                    if currentPage < totalPages - 1 {
                        GhostButton(title: "Skip") {
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentPage = totalPages - 1
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 8)
                .frame(height: 44)
                
                // Page Content
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    photosPage
                        .tag(1)
                    
                    storagePage
                        .tag(2)
                    
                    featuresPage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // CTA Button
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: currentPage < totalPages - 1 ? "Continue" : "Get Started",
                        icon: currentPage < totalPages - 1 ? nil : "arrow.right"
                    ) {
                        if currentPage < totalPages - 1 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            appState.completeOnboarding()
                        }
                    }
                    
                    // Terms
                    if currentPage == totalPages - 1 {
                        Text("By continuing, you agree to our Terms & Privacy Policy")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        OnboardingPageView(
            icon: "sparkles",
            iconColor: AppColors.accentGlow,
            title: "Welcome to Cleaner",
            subtitle: "The smartest way to free up space on your iPhone and keep it organized."
        )
    }
    
    // MARK: - Page 2: Photos
    
    private var photosPage: some View {
        OnboardingPageView(
            icon: "photo.stack.fill",
            iconColor: AppColors.accentBlue,
            title: "Clean Your Photos",
            subtitle: "Find and remove duplicates, similar photos, screenshots, and Live Photos to save gigabytes of space."
        )
    }
    
    // MARK: - Page 3: Storage
    
    private var storagePage: some View {
        OnboardingPageView(
            icon: "externaldrive.fill",
            iconColor: AppColors.accentPurple,
            title: "Analyze Storage",
            subtitle: "Get detailed insights about what's taking up space on your device and clean it with one tap."
        )
    }
    
    // MARK: - Page 4: Features
    
    private var featuresPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.statusSuccess.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            // Text
            VStack(spacing: 12) {
                Text("Powerful Features")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Contacts cleaner, video compression, secret folder, and more - all in one app.")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Feature Pills
            HStack(spacing: 8) {
                featurePill(icon: "person.2.fill", text: "Contacts")
                featurePill(icon: "video.fill", text: "Videos")
                featurePill(icon: "lock.fill", text: "Secret")
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            
            Text(text)
                .font(AppFonts.caption)
        }
        .foregroundColor(AppColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.backgroundSecondary.opacity(0.6))
        .cornerRadius(20)
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(title)
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState.shared)
    }
}

