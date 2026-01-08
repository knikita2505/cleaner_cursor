import SwiftUI

// MARK: - Secret Space Home View
/// Главный экран Secret Space согласно secret_home.md

struct SecretSpaceHomeView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var secretService = SecretSpaceService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    
    @State private var showPasscodeSetup = false
    @State private var showPaywall = false
    @State private var showUnlockSheet = false
    @State private var pendingDestination: SecretDestination?
    @State private var showFeatureTip: Bool = false
    @State private var hasAppeared: Bool = false
    
    // Навигация
    @State private var navigationPath = NavigationPath()
    
    private let tipService = FeatureTipService.shared
    
    enum SecretDestination: Hashable {
        case album
        case contacts
        case protection
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        if !subscriptionService.isPremium {
                            premiumBanner
                        }
                        
                        sectionsView
                        protectionView
                        statusView
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: SecretDestination.self) { destination in
                switch destination {
                case .album:
                    SecretAlbumView()
                case .contacts:
                    SecretContactsView()
                case .protection:
                    ProtectionSettingsView()
                }
            }
            .fullScreenCover(isPresented: $showPasscodeSetup) {
                PasscodeView(mode: .create, onSuccess: {
                    showPasscodeSetup = false
                    if let dest = pendingDestination {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigationPath.append(dest)
                            pendingDestination = nil
                        }
                    }
                }, onCancel: {
                    showPasscodeSetup = false
                    pendingDestination = nil
                })
            }
            .fullScreenCover(isPresented: $showUnlockSheet) {
                PasscodeView(mode: .unlock, onSuccess: {
                    showUnlockSheet = false
                    if let dest = pendingDestination {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigationPath.append(dest)
                            pendingDestination = nil
                        }
                    }
                }, onCancel: {
                    showUnlockSheet = false
                    pendingDestination = nil
                })
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showFeatureTip) {
                FeatureTipView(tipData: .secretSpace) {
                    tipService.markTipAsShown(for: .secretSpace)
                    showFeatureTip = false
                }
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                
                // Show feature tip on first visit
                if tipService.shouldShowTip(for: .secretSpace) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFeatureTip = true
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func handleSectionTap(_ destination: SecretDestination) {
        guard subscriptionService.isPremium else {
            showPaywall = true
            return
        }
        
        pendingDestination = destination
        
        if !secretService.isPasscodeSet {
            showPasscodeSetup = true
        } else {
            showUnlockSheet = true
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.accentLilac.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.accentLilac)
            }
            .padding(.top, 20)
            
            Text("Secret Space")
                .font(AppFonts.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Hide your private photos, videos and contacts.")
                .font(AppFonts.bodyL)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Premium Banner
    
    private var premiumBanner: some View {
        Button {
            showPaywall = true
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
                    Text("Start Free Trial")
                        .font(AppFonts.subtitleL)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Secret Space is a Premium feature")
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
                    colors: [AppColors.accentPurple.opacity(0.2), AppColors.accentBlue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppSpacing.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardRadius)
                    .stroke(AppColors.accentPurple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    // MARK: - Sections
    
    private var sectionsView: some View {
        VStack(spacing: 12) {
            sectionButton(
                icon: "photo.on.rectangle.angled",
                iconColor: AppColors.accentBlue,
                title: "Secret Album",
                subtitle: "\(secretService.secretPhotos.count + secretService.secretVideos.count) items",
                destination: .album
            )
            
            sectionButton(
                icon: "person.crop.circle.fill",
                iconColor: AppColors.statusSuccess,
                title: "Secret Contacts",
                subtitle: "\(secretService.secretContacts.count) contacts",
                destination: .contacts
            )
        }
    }
    
    private func sectionButton(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        destination: SecretDestination
    ) -> some View {
        Button {
            handleSectionTap(destination)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if secretService.isPasscodeSet {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .disabled(!subscriptionService.isPremium)
        .opacity(subscriptionService.isPremium ? 1 : 0.6)
    }
    
    // MARK: - Protection Settings
    
    private var protectionView: some View {
        NavigationLink(value: SecretDestination.protection) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.accentPurple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Access Settings")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(protectionSubtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if secretService.isPasscodeSet {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.statusSuccess)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(.plain)
        .disabled(!subscriptionService.isPremium)
        .opacity(subscriptionService.isPremium ? 1 : 0.6)
    }
    
    private var protectionSubtitle: String {
        if secretService.isPasscodeSet {
            if secretService.isFaceIDEnabled {
                return "Passcode + \(secretService.biometricType.name)"
            }
            return "Passcode enabled"
        }
        return "Set up passcode"
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary)
            
            Text("\(secretService.totalHiddenCount) items hidden")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

struct SecretSpaceHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SecretSpaceHomeView()
            .environmentObject(AppState.shared)
    }
}
