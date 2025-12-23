import SwiftUI

// MARK: - Protection Settings View
/// Экран настроек защиты Secret Space

struct ProtectionSettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var secretService = SecretSpaceService.shared
    
    @State private var showPasscodeSetup = false
    @State private var showPasscodeChange = false
    @State private var showUnlockForFaceID = false
    @State private var pendingFaceIDState = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Passcode section
                    passcodeSection
                    
                    // Biometric section
                    if secretService.isBiometricAvailable && secretService.isPasscodeSet {
                        biometricSection
                    }
                    
                    // Info
                    infoSection
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .navigationTitle("Protection")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPasscodeSetup) {
            PasscodeView(mode: .create, onSuccess: {
                showPasscodeSetup = false
            }, onCancel: {
                showPasscodeSetup = false
            })
        }
        .fullScreenCover(isPresented: $showPasscodeChange) {
            PasscodeView(mode: .change, onSuccess: {
                showPasscodeChange = false
            }, onCancel: {
                showPasscodeChange = false
            })
        }
        .fullScreenCover(isPresented: $showUnlockForFaceID) {
            PasscodeView(mode: .unlock, onSuccess: {
                showUnlockForFaceID = false
                // Включаем/выключаем Face ID после проверки пинкода
                secretService.setFaceIDEnabled(pendingFaceIDState)
            }, onCancel: {
                showUnlockForFaceID = false
            })
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.accentPurple.opacity(0.15))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.accentPurple)
            }
            
            Text("Protect Your Data")
                .font(AppFonts.titleM)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Set up passcode and biometric authentication")
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - Passcode Section
    
    private var passcodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Passcode")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
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
                                .fill(AppColors.accentBlue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: secretService.isPasscodeSet ? "lock.fill" : "lock.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accentBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(secretService.isPasscodeSet ? "Change Passcode" : "Set Passcode")
                                .font(AppFonts.subtitleM)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(secretService.isPasscodeSet ? "Update your 4-digit passcode" : "Required to access Secret Space")
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
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    // MARK: - Biometric Section
    
    private var biometricSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(secretService.biometricType.name)
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.accentLilac.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: secretService.biometricType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.accentLilac)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use \(secretService.biometricType.name)")
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Quick unlock with biometrics")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { secretService.isFaceIDEnabled },
                        set: { newValue in
                            // Требуем пинкод для изменения настройки
                            pendingFaceIDState = newValue
                            showUnlockForFaceID = true
                        }
                    ))
                    .tint(AppColors.accentBlue)
                }
                .padding(AppSpacing.containerPadding)
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                
                Text("Your data is stored securely on this device")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.statusWarning)
                
                Text("If you forget your passcode, data cannot be recovered")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

struct ProtectionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProtectionSettingsView()
        }
    }
}
