import SwiftUI

// MARK: - Empty State View
/// Компонент для отображения пустых состояний

struct EmptyStateView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        description: String,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(iconColor.opacity(0.6))
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Button
            if let buttonTitle = buttonTitle, let action = action {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Success State View
/// Компонент для отображения успешного состояния

struct SuccessStateView: View {
    let title: String
    let description: String
    let stats: [(title: String, value: String)]?
    let buttonTitle: String
    let action: () -> Void
    
    init(
        title: String = "All Done!",
        description: String,
        stats: [(title: String, value: String)]? = nil,
        buttonTitle: String = "Continue",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.stats = stats
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(AppColors.statusSuccess.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(title)
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Stats
            if let stats = stats, !stats.isEmpty {
                HStack(spacing: 16) {
                    ForEach(stats.indices, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(stats[index].value)
                                .font(AppFonts.titleM)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(stats[index].title)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(16)
                    }
                }
            }
            
            // Button
            PrimaryButton(title: buttonTitle, action: action)
        }
        .padding(AppSpacing.screenPadding)
    }
}

// MARK: - Loading State View
/// Компонент для отображения загрузки

struct LoadingStateView: View {
    let title: String
    let description: String?
    let progress: Double?
    
    init(
        title: String = "Loading...",
        description: String? = nil,
        progress: Double? = nil
    ) {
        self.title = title
        self.description = description
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if let progress = progress {
                CircularProgress(
                    progress: progress,
                    lineWidth: 6,
                    size: 80,
                    showPercentage: true,
                    gradient: AppGradients.ctaGradient
                )
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentBlue))
                    .scaleEffect(1.5)
                    .frame(width: 80, height: 80)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                if let description = description {
                    Text(description)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Error State View
/// Компонент для отображения ошибки

struct ErrorStateView: View {
    let title: String
    let description: String
    let retryTitle: String
    let retryAction: () -> Void
    
    init(
        title: String = "Something went wrong",
        description: String,
        retryTitle: String = "Try Again",
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(AppColors.statusError.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppColors.statusError.opacity(0.8))
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            
            // Retry Button
            SecondaryButton(title: retryTitle, icon: "arrow.clockwise", action: retryAction)
                .padding(.horizontal, AppSpacing.screenPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

struct EmptyState_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                EmptyStateView(
                    icon: "photo.stack",
                    title: "No Duplicates Found",
                    description: "Your photo library is clean! No duplicate photos were detected.",
                    buttonTitle: "Scan Again"
                ) {
                    print("Scan")
                }
                
                Divider().background(AppColors.borderSecondary)
                
                SuccessStateView(
                    description: "You've successfully cleaned up your photo library",
                    stats: [
                        (title: "Deleted", value: "234"),
                        (title: "Saved", value: "2.4 GB")
                    ]
                ) {
                    print("Continue")
                }
                
                Divider().background(AppColors.borderSecondary)
                
                LoadingStateView(
                    title: "Scanning Photos...",
                    description: "This may take a few moments",
                    progress: 0.65
                )
                
                Divider().background(AppColors.borderSecondary)
                
                ErrorStateView(
                    description: "We couldn't scan your photos. Please try again."
                ) {
                    print("Retry")
                }
            }
        }
        .background(AppColors.backgroundPrimary)
    }
}

