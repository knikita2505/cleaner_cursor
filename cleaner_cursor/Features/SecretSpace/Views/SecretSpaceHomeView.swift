import SwiftUI

// MARK: - Secret Space Home View
/// Главный экран Secret Space согласно secret_home.md

struct SecretSpaceHomeView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var secretService = SecretSpaceService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    
    @State private var showPasscodeSetup = false
    @State private var showPasscodeChange = false
    @State private var showUnlock = false
    @State private var showPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Premium banner (if not premium)
                        if !subscriptionService.isPremium {
                            premiumBanner
                        }
                        
                        // Sections
                        sectionsView
                        
                        // Protection settings
                        protectionView
                        
                        // Hidden items status
                        statusView
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showPasscodeSetup) {
                PasscodeView(mode: .create) {
                    showPasscodeSetup = false
                    // После создания пароля автоматически разблокируем
                    secretService.unlock()
                }
            }
            .fullScreenCover(isPresented: $showPasscodeChange) {
                PasscodeView(mode: .change) {
                    showPasscodeChange = false
                }
            }
            .fullScreenCover(isPresented: $showUnlock) {
                PasscodeView(mode: .unlock) {
                    showUnlock = false
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Icon
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
            // Secret Album
            sectionButton(
                icon: "photo.on.rectangle.angled",
                iconColor: AppColors.accentBlue,
                title: "Secret Album",
                subtitle: "\(secretService.secretPhotos.count + secretService.secretVideos.count) items",
                destination: {
                    AnyView(SecretAlbumView())
                }
            )
            
            // Secret Contacts
            sectionButton(
                icon: "person.crop.circle.fill",
                iconColor: AppColors.statusSuccess,
                title: "Secret Contacts",
                subtitle: "\(secretService.secretContacts.count) contacts",
                destination: {
                    AnyView(SecretContactsView())
                }
            )
        }
    }
    
    private func sectionButton<Destination: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        destination: @escaping () -> Destination
    ) -> some View {
        Button {
            handleSectionTap {
                // Навигация обрабатывается через NavigationLink
            }
        } label: {
            NavigationLink {
                if secretService.isUnlocked || !secretService.isPasscodeSet {
                    destination()
                } else {
                    PasscodeView(mode: .unlock) {
                        // После разблокировки покажем destination
                    }
                }
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
                    
                    // Lock indicator if locked
                    if secretService.isPasscodeSet && !secretService.isUnlocked {
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
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .disabled(!subscriptionService.isPremium)
        .opacity(subscriptionService.isPremium ? 1 : 0.6)
    }
    
    private func handleSectionTap(action: @escaping () -> Void) {
        guard subscriptionService.isPremium else {
            showPaywall = true
            return
        }
        
        if !secretService.isPasscodeSet {
            showPasscodeSetup = true
            return
        }
        
        if !secretService.isUnlocked {
            showUnlock = true
            return
        }
        
        action()
    }
    
    // MARK: - Protection Settings
    
    private var protectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protection")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 2) {
                // Set Passcode
                Button {
                    if secretService.isPasscodeSet {
                        showPasscodeChange = true
                    } else {
                        showPasscodeSetup = true
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.accentPurple.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accentPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(secretService.isPasscodeSet ? "Change Passcode" : "Set Passcode")
                                .font(AppFonts.subtitleM)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(secretService.isPasscodeSet ? "Update your 4-digit passcode" : "Create a 4-digit passcode")
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
                }
                .disabled(!subscriptionService.isPremium)
                
                Divider()
                    .background(AppColors.textTertiary.opacity(0.1))
                    .padding(.leading, 72)
                
                // Face ID / Touch ID
                if secretService.isBiometricAvailable {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.accentBlue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: secretService.biometricType.icon)
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accentBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(secretService.biometricType.name)
                                .font(AppFonts.subtitleM)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Quick unlock with \(secretService.biometricType.name)")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { secretService.isFaceIDEnabled },
                            set: { secretService.setFaceIDEnabled($0) }
                        ))
                        .tint(AppColors.accentBlue)
                        .disabled(!secretService.isPasscodeSet || !subscriptionService.isPremium)
                    }
                    .padding(AppSpacing.containerPadding)
                    .opacity(secretService.isPasscodeSet ? 1 : 0.5)
                }
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
            .opacity(subscriptionService.isPremium ? 1 : 0.6)
        }
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

