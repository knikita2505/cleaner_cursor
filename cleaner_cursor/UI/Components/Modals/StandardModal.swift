import SwiftUI

// MARK: - Standard Modal
/// Стандартное модальное окно
/// Background: #0F1116, Radius: 32pt

struct StandardModal<Content: View>: View {
    let title: String
    let subtitle: String?
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    let content: () -> Content
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        subtitle: String? = nil,
        primaryButtonTitle: String = "Continue",
        secondaryButtonTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text(title)
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.bodyL)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Content
            content()
            
            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: primaryButtonTitle, action: primaryAction)
                
                if let secondaryTitle = secondaryButtonTitle,
                   let secondaryAction = secondaryAction {
                    SecondaryButton(title: secondaryTitle, action: secondaryAction)
                }
            }
        }
        .padding(AppSpacing.containerPaddingLarge)
        .padding(.top, 8)
        .background(AppColors.backgroundModal)
        .cornerRadius(AppSpacing.modalRadius)
        .shadow(color: AppShadow.medium.color, radius: AppShadow.medium.radius, x: AppShadow.medium.x, y: AppShadow.medium.y)
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - Permission Modal
/// Модальное окно для запроса разрешений
/// Fullscreen, большая иконка 80pt

struct PermissionModal: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        description: String,
        primaryButtonTitle: String = "Allow Access",
        secondaryButtonTitle: String? = "Not Now",
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: AppSpacing.iconPermission, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text Content
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
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: primaryButtonTitle, action: primaryAction)
                
                if let secondaryTitle = secondaryButtonTitle,
                   let secondaryAction = secondaryAction {
                    GhostButton(title: secondaryTitle, action: secondaryAction)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
}

// MARK: - Alert Modal
/// Простое модальное окно с сообщением

struct AlertModal: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    init(
        icon: String? = nil,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        message: String,
        buttonTitle: String = "OK",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(title: buttonTitle, action: action)
        }
        .padding(AppSpacing.containerPaddingLarge)
        .background(AppColors.backgroundModal)
        .cornerRadius(AppSpacing.modalRadius)
        .padding(.horizontal, 40)
    }
}

// MARK: - Modal Background Overlay

struct ModalOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
                
                content()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: isPresented)
    }
}

// MARK: - Preview

struct StandardModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack {
                // Permission Modal Preview
                PermissionModal(
                    icon: "photo.fill",
                    iconColor: AppColors.accentPurple,
                    title: "Access Your Photos",
                    description: "We need access to your photos to find duplicates and help you free up space.",
                    primaryAction: { print("Allow") },
                    secondaryAction: { print("Not Now") }
                )
            }
        }
    }
}

