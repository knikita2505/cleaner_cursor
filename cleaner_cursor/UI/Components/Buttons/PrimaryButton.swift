import SwiftUI

// MARK: - Primary Button
/// Основная CTA кнопка с градиентом
/// Height: 56pt, Corner radius: 16pt, Background: CTA Gradient

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.iconTextSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(title)
                        .font(AppFonts.buttonPrimary)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.buttonHeight)
            .background(AppGradients.ctaGradient)
            .cornerRadius(AppSpacing.buttonRadius)
            .gradientShadow()
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Secondary Button
/// Кнопка с обводкой без заливки

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.iconTextSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(AppFonts.buttonSecondary)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.buttonHeightSecondary)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                    .stroke(AppColors.borderSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Ghost Button
/// Минимальная кнопка без фона

struct GhostButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(AppFonts.buttonSecondary)
            }
            .foregroundColor(AppColors.textSecondary.opacity(0.7))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Icon Button
/// Кнопка только с иконкой

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = AppColors.textSecondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
                .frame(width: size + 16, height: size + 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
/// Анимация нажатия с уменьшением на 3-5%

struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    
    init(scale: CGFloat = 0.95) {
        self.scale = scale
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                PrimaryButton(title: "Continue", icon: "arrow.right") {
                    print("Primary tapped")
                }
                
                PrimaryButton(title: "Loading...", isLoading: true) {
                    print("Loading")
                }
                
                SecondaryButton(title: "Skip", icon: "xmark") {
                    print("Secondary tapped")
                }
                
                GhostButton(title: "Restore Purchase") {
                    print("Ghost tapped")
                }
                
                HStack {
                    IconButton(icon: "gearshape") {
                        print("Settings")
                    }
                    
                    IconButton(icon: "xmark", color: AppColors.accentBlue) {
                        print("Close")
                    }
                }
            }
            .padding()
        }
    }
}

