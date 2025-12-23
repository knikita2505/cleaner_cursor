import SwiftUI

// MARK: - Passcode View
/// Экран для ввода или создания PIN-кода

struct PasscodeView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var secretService = SecretSpaceService.shared
    
    let mode: PasscodeMode
    let onSuccess: () -> Void
    
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var isConfirming: Bool = false
    @State private var errorMessage: String?
    @State private var shake: Bool = false
    
    private let passcodeLength = 4
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                iconView
                
                // Title
                titleView
                
                // Dots
                dotsView
                    .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.statusError)
                }
                
                Spacer()
                
                // Keypad
                keypadView
                
                // Cancel button
                if mode != .unlock {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Попытка Face ID при разблокировке
            if mode == .unlock && secretService.isFaceIDEnabled {
                Task {
                    if await secretService.authenticateWithBiometrics() {
                        onSuccess()
                    }
                }
            }
        }
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(AppColors.accentLilac.opacity(0.15))
                .frame(width: 80, height: 80)
            
            Image(systemName: iconName)
                .font(.system(size: 36))
                .foregroundColor(AppColors.accentLilac)
        }
    }
    
    private var iconName: String {
        switch mode {
        case .create, .confirm:
            return "lock.badge.plus"
        case .unlock:
            return "lock.fill"
        case .change:
            return "lock.rotation"
        }
    }
    
    // MARK: - Title View
    
    private var titleView: some View {
        VStack(spacing: 8) {
            Text(titleText)
                .font(AppFonts.titleL)
                .foregroundColor(AppColors.textPrimary)
            
            Text(subtitleText)
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var titleText: String {
        switch mode {
        case .create:
            return isConfirming ? "Confirm Passcode" : "Create Passcode"
        case .confirm:
            return "Enter Passcode"
        case .unlock:
            return "Unlock Secret Space"
        case .change:
            return isConfirming ? "Enter New Passcode" : "Enter Current Passcode"
        }
    }
    
    private var subtitleText: String {
        switch mode {
        case .create:
            return isConfirming ? "Enter your passcode again" : "Create a 4-digit passcode to protect your data"
        case .confirm, .unlock:
            return "Enter your 4-digit passcode"
        case .change:
            return isConfirming ? "Create a new 4-digit passcode" : "Verify your current passcode"
        }
    }
    
    // MARK: - Dots View
    
    private var dotsView: some View {
        HStack(spacing: 20) {
            ForEach(0..<passcodeLength, id: \.self) { index in
                Circle()
                    .fill(index < currentPasscode.count ? AppColors.accentBlue : AppColors.textTertiary.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .animation(.easeInOut(duration: 0.1), value: currentPasscode.count)
            }
        }
    }
    
    private var currentPasscode: String {
        isConfirming ? confirmPasscode : passcode
    }
    
    // MARK: - Keypad View
    
    private var keypadView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { row in
                HStack(spacing: 24) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        keypadButton(String(number))
                    }
                }
            }
            
            // Bottom row: Biometric, 0, Delete
            HStack(spacing: 24) {
                // Biometric button (only in unlock mode)
                if mode == .unlock && secretService.isFaceIDEnabled && secretService.isBiometricAvailable {
                    Button {
                        Task {
                            if await secretService.authenticateWithBiometrics() {
                                onSuccess()
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: secretService.biometricType.icon)
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.accentBlue)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 72, height: 72)
                }
                
                keypadButton("0")
                
                // Delete button
                Button {
                    deleteDigit()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }
    
    private func keypadButton(_ digit: String) -> some View {
        Button {
            addDigit(digit)
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundSecondary)
                    .frame(width: 72, height: 72)
                
                Text(digit)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }
    
    // MARK: - Input Handling
    
    private func addDigit(_ digit: String) {
        HapticManager.lightImpact()
        errorMessage = nil
        
        if isConfirming {
            guard confirmPasscode.count < passcodeLength else { return }
            confirmPasscode += digit
            
            if confirmPasscode.count == passcodeLength {
                handleConfirmComplete()
            }
        } else {
            guard passcode.count < passcodeLength else { return }
            passcode += digit
            
            if passcode.count == passcodeLength {
                handlePasscodeComplete()
            }
        }
    }
    
    private func deleteDigit() {
        if isConfirming {
            if !confirmPasscode.isEmpty {
                confirmPasscode.removeLast()
            }
        } else {
            if !passcode.isEmpty {
                passcode.removeLast()
            }
        }
        errorMessage = nil
    }
    
    private func handlePasscodeComplete() {
        switch mode {
        case .create:
            // Переходим к подтверждению
            withAnimation {
                isConfirming = true
            }
            
        case .confirm, .unlock:
            if secretService.verifyPasscode(passcode) {
                HapticManager.success()
                secretService.unlock()
                onSuccess()
            } else {
                showError("Incorrect passcode")
            }
            
        case .change:
            if secretService.verifyPasscode(passcode) {
                withAnimation {
                    isConfirming = true
                    passcode = ""
                }
            } else {
                showError("Incorrect passcode")
            }
        }
    }
    
    private func handleConfirmComplete() {
        switch mode {
        case .create:
            if confirmPasscode == passcode {
                if secretService.setPasscode(passcode) {
                    HapticManager.success()
                    onSuccess()
                } else {
                    showError("Failed to save passcode")
                }
            } else {
                showError("Passcodes don't match")
                confirmPasscode = ""
            }
            
        case .change:
            if secretService.setPasscode(confirmPasscode) {
                HapticManager.success()
                onSuccess()
            } else {
                showError("Failed to save passcode")
            }
            
        default:
            break
        }
    }
    
    private func showError(_ message: String) {
        HapticManager.error()
        errorMessage = message
        passcode = ""
        confirmPasscode = ""
        isConfirming = false
        
        // Shake animation
        withAnimation(.default) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shake = false
        }
    }
}

// MARK: - Passcode Mode

enum PasscodeMode {
    case create
    case confirm
    case unlock
    case change
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 4) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Preview

struct PasscodeView_Previews: PreviewProvider {
    static var previews: some View {
        PasscodeView(mode: .create) { }
    }
}

