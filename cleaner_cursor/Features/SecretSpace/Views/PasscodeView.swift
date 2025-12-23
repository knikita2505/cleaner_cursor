import SwiftUI

// MARK: - Passcode View
/// Экран для ввода или создания PIN-кода

struct PasscodeView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var secretService = SecretSpaceService.shared
    
    let mode: PasscodeMode
    let onSuccess: () -> Void
    var onCancel: (() -> Void)?
    
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var isConfirming: Bool = false
    @State private var errorMessage: String?
    @State private var shake: Bool = false
    
    // Блокировка после неверных попыток
    @State private var failedAttempts: Int = 0
    @State private var isLocked: Bool = false
    @State private var lockEndTime: Date?
    @State private var remainingLockTime: Int = 0
    @State private var lockTimer: Timer?
    
    private let passcodeLength = 4
    private let maxFailedAttempts = 5
    private let lockDurationSeconds = 180 // 3 минуты
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Spacer()
                    Button {
                        handleCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textTertiary.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Main content - fixed height container
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isLocked ? AppColors.statusError.opacity(0.15) : AppColors.accentLilac.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: isLocked ? "lock.fill" : iconName)
                            .font(.system(size: 32))
                            .foregroundColor(isLocked ? AppColors.statusError : AppColors.accentLilac)
                    }
                    
                    // Title
                    VStack(spacing: 6) {
                        Text(isLocked ? "Too Many Attempts" : titleText)
                            .font(AppFonts.titleM)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(isLocked ? "Try again in \(formatTime(remainingLockTime))" : subtitleText)
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    // Dots
                    if !isLocked {
                        HStack(spacing: 16) {
                            ForEach(0..<passcodeLength, id: \.self) { index in
                                Circle()
                                    .fill(index < currentPasscode.count ? AppColors.accentBlue : AppColors.textTertiary.opacity(0.3))
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
                    }
                    
                    // Error message - fixed height to prevent layout shift
                    Text(errorMessage ?? " ")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusError)
                        .frame(height: 16)
                        .opacity(errorMessage != nil ? 1 : 0)
                }
                .frame(height: 220)
                
                Spacer()
                
                // Keypad
                keypadView
                    .opacity(isLocked ? 0.3 : 1)
                    .disabled(isLocked)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkLockStatus()
            attemptBiometricAuth()
        }
        .onDisappear {
            lockTimer?.invalidate()
        }
    }
    
    // MARK: - Biometric Auth
    
    private func attemptBiometricAuth() {
        guard mode == .unlock && secretService.isFaceIDEnabled && !isLocked else { return }
        
        Task {
            if await secretService.authenticateWithBiometrics() {
                onSuccess()
            }
        }
    }
    
    // MARK: - Cancel Handler
    
    private func handleCancel() {
        lockTimer?.invalidate()
        if let onCancel = onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    // MARK: - Lock Status
    
    private func checkLockStatus() {
        if let endTime = UserDefaults.standard.object(forKey: "passcode_lock_end_time") as? Date {
            if endTime > Date() {
                isLocked = true
                lockEndTime = endTime
                startLockTimer()
            } else {
                clearLock()
            }
        }
        failedAttempts = UserDefaults.standard.integer(forKey: "passcode_failed_attempts")
    }
    
    private func startLockTimer() {
        updateRemainingTime()
        lockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemainingTime()
        }
    }
    
    private func updateRemainingTime() {
        guard let endTime = lockEndTime else { return }
        let remaining = Int(endTime.timeIntervalSince(Date()))
        if remaining <= 0 {
            clearLock()
        } else {
            remainingLockTime = remaining
        }
    }
    
    private func clearLock() {
        isLocked = false
        lockEndTime = nil
        remainingLockTime = 0
        failedAttempts = 0
        lockTimer?.invalidate()
        UserDefaults.standard.removeObject(forKey: "passcode_lock_end_time")
        UserDefaults.standard.set(0, forKey: "passcode_failed_attempts")
    }
    
    private func activateLock() {
        let endTime = Date().addingTimeInterval(TimeInterval(lockDurationSeconds))
        lockEndTime = endTime
        isLocked = true
        UserDefaults.standard.set(endTime, forKey: "passcode_lock_end_time")
        startLockTimer()
    }
    
    // MARK: - Computed Properties
    
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
    
    private var titleText: String {
        switch mode {
        case .create:
            return isConfirming ? "Confirm Passcode" : "Create Passcode"
        case .confirm:
            return "Enter Passcode"
        case .unlock:
            return "Enter Passcode"
        case .change:
            return isConfirming ? "New Passcode" : "Current Passcode"
        }
    }
    
    private var subtitleText: String {
        switch mode {
        case .create:
            return isConfirming ? "Re-enter your passcode" : "Create a 4-digit passcode"
        case .confirm, .unlock:
            return "Enter your 4-digit passcode"
        case .change:
            return isConfirming ? "Enter new passcode" : "Verify current passcode"
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
            
            // Bottom row
            HStack(spacing: 24) {
                // Biometric button
                if mode == .unlock && secretService.isFaceIDEnabled && secretService.isBiometricAvailable && !isLocked {
                    Button {
                        attemptBiometricAuth()
                    } label: {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 76, height: 76)
                            .overlay {
                                Image(systemName: secretService.biometricType.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.accentBlue)
                            }
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 76, height: 76)
                }
                
                keypadButton("0")
                
                // Delete button
                Button {
                    deleteDigit()
                } label: {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 76, height: 76)
                        .overlay {
                            Image(systemName: "delete.left")
                                .font(.system(size: 26))
                                .foregroundColor(AppColors.textSecondary)
                        }
                }
                .disabled(isLocked)
            }
        }
    }
    
    private func keypadButton(_ digit: String) -> some View {
        Button {
            addDigit(digit)
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundSecondary)
                    .frame(width: 76, height: 76)
                
                Text(digit)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .disabled(isLocked)
    }
    
    // MARK: - Input Handling
    
    private func addDigit(_ digit: String) {
        guard !isLocked else { return }
        
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
            if !confirmPasscode.isEmpty { confirmPasscode.removeLast() }
        } else {
            if !passcode.isEmpty { passcode.removeLast() }
        }
        errorMessage = nil
    }
    
    private func handlePasscodeComplete() {
        switch mode {
        case .create:
            withAnimation { isConfirming = true }
            
        case .confirm, .unlock:
            if secretService.verifyPasscode(passcode) {
                HapticManager.success()
                secretService.unlock()
                clearLock()
                onSuccess()
            } else {
                handleFailedAttempt()
            }
            
        case .change:
            if secretService.verifyPasscode(passcode) {
                withAnimation {
                    isConfirming = true
                    passcode = ""
                }
            } else {
                handleFailedAttempt()
            }
        }
    }
    
    private func handleFailedAttempt() {
        failedAttempts += 1
        UserDefaults.standard.set(failedAttempts, forKey: "passcode_failed_attempts")
        
        if failedAttempts >= maxFailedAttempts {
            activateLock()
            showError("Locked for 3 minutes")
        } else {
            let remaining = maxFailedAttempts - failedAttempts
            showError("\(remaining) attempts remaining")
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
                    showError("Failed to save")
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
                showError("Failed to save")
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
        if mode == .create { isConfirming = false }
        
        withAnimation(.default) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
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
        PasscodeView(mode: .unlock) { }
    }
}
