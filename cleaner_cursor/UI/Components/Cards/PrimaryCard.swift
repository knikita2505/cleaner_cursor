import SwiftUI

// MARK: - Primary Card
/// Основная карточка с иконкой, заголовком и CTA indicator
/// Background: #111214, Radius: 20pt, Padding: 20pt

struct PrimaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let badge: String?
    let showChevron: Bool
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.containerPadding) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(AppFonts.subtitleL)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(AppFonts.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.accentPurple)
                                .cornerRadius(8)
                        }
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.containerPaddingLarge)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
            .shadow(color: AppShadow.soft.color, radius: AppShadow.soft.radius, x: AppShadow.soft.x, y: AppShadow.soft.y)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - List Card
/// Карточка для списка Scanner / Photo categories
/// Row-style, Height: 72-80pt

struct ListCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let counter: String?
    let subtitle: String?
    let showChevron: Bool
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        counter: String? = nil,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.counter = counter
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.containerPadding) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Counter
                if let counter = counter {
                    Text(counter)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.accentBlue)
                }
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary.opacity(0.6))
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
            .frame(height: AppSpacing.listRowHeight)
            .background(AppColors.backgroundCard)
            .cornerRadius(AppSpacing.buttonRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Stats Card
/// Карточка для отображения статистики

struct StatsCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String?
    
    init(
        icon: String,
        iconColor: Color = AppColors.accentBlue,
        title: String,
        value: String,
        unit: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Value
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Title
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
}

// MARK: - Preview

struct PrimaryCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    PrimaryCard(
                        icon: "photo.stack",
                        iconColor: AppColors.accentPurple,
                        title: "Duplicate Photos",
                        subtitle: "Find and remove duplicate photos",
                        badge: "PRO"
                    ) {
                        print("Tapped")
                    }
                    
                    ListCard(
                        icon: "photo.on.rectangle",
                        iconColor: AppColors.statusSuccess,
                        title: "Screenshots",
                        counter: "234"
                    ) {
                        print("Screenshots")
                    }
                    
                    ListCard(
                        icon: "livephoto",
                        iconColor: AppColors.statusWarning,
                        title: "Live Photos",
                        counter: "89",
                        subtitle: "Save 1.2 GB"
                    ) {
                        print("Live Photos")
                    }
                    
                    HStack(spacing: 12) {
                        StatsCard(
                            icon: "photo",
                            iconColor: AppColors.accentBlue,
                            title: "Photos",
                            value: "2,456"
                        )
                        
                        StatsCard(
                            icon: "video",
                            iconColor: AppColors.accentPurple,
                            title: "Videos",
                            value: "128"
                        )
                    }
                }
                .padding()
            }
        }
    }
}

