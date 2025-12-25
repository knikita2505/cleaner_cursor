import SwiftUI

// MARK: - Device Health View
/// Главный экран Device Health с общим индексом состояния устройства

struct DeviceHealthView: View {
    
    // MARK: - Properties
    
    @StateObject private var healthService = DeviceHealthService.shared
    @StateObject private var storageService = StorageService.shared
    @StateObject private var batteryService = BatteryService.shared
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Health Score Card
                    healthScoreCard
                    
                    // Categories
                    categoriesSection
                    
                    // View Tips Button
                    viewTipsButton
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .navigationTitle("Device Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthService.refresh()
        }
    }
    
    // MARK: - Health Score Card
    
    private var healthScoreCard: some View {
        VStack(spacing: 12) {
            // Score Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        AppColors.textTertiary.opacity(0.2),
                        lineWidth: 10
                    )
                    .frame(width: 100, height: 100)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(healthService.healthScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: healthGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: healthService.healthScore)
                
                // Score text
                VStack(spacing: 2) {
                    Text("\(healthService.healthScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(healthService.healthStatus.color)
                    
                    Text("Score")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Status badge
            HStack(spacing: 6) {
                Image(systemName: healthService.healthStatus.icon)
                    .font(.system(size: 14))
                
                Text(healthService.healthStatus.title)
                    .font(AppFonts.bodyM)
            }
            .foregroundColor(healthService.healthStatus.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(healthService.healthStatus.color.opacity(0.15))
            .cornerRadius(16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private var healthGradientColors: [Color] {
        switch healthService.healthStatus {
        case .excellent:
            return [AppColors.statusSuccess, AppColors.statusSuccess.opacity(0.7)]
        case .good:
            return [AppColors.accentBlue, AppColors.accentLilac]
        case .needsAttention:
            return [AppColors.statusWarning, AppColors.statusWarning.opacity(0.7)]
        case .critical:
            return [AppColors.statusError, AppColors.statusError.opacity(0.7)]
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(spacing: 2) {
            // Storage - переключает на таб Clean
            Button {
                appState.selectedTab = .clean
            } label: {
                categoryRow(
                    icon: "internaldrive.fill",
                    title: "Storage",
                    subtitle: "\(Int((storageService.storageInfo?.usagePercentage ?? 0) * 100))% used",
                    status: healthService.storageStatus,
                    score: healthService.storageScore,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(AppColors.textTertiary.opacity(0.1))
                .padding(.leading, 52)
            
            // Battery
            NavigationLink(value: MoreDestination.batteryInsights) {
                categoryRow(
                    icon: "battery.75",
                    title: "Battery",
                    subtitle: "\(batteryService.batteryPercentage)% • \(batteryService.batteryStateDescription)",
                    status: healthService.batteryStatus,
                    score: healthService.batteryScore,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(AppColors.textTertiary.opacity(0.1))
                .padding(.leading, 52)
            
            // Performance
            categoryRow(
                icon: "speedometer",
                title: "Performance",
                subtitle: "Uptime: \(healthService.uptimeDescription)",
                status: healthService.performanceStatus,
                score: healthService.performanceScore,
                showChevron: false
            )
            
            Divider()
                .background(AppColors.textTertiary.opacity(0.1))
                .padding(.leading, 52)
            
            // Temperature
            categoryRow(
                icon: "thermometer.medium",
                title: "Temperature",
                subtitle: healthService.thermalStateDescription,
                status: healthService.temperatureStatus,
                score: healthService.temperatureScore,
                showChevron: false
            )
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func categoryRow(
        icon: String,
        title: String,
        subtitle: String,
        status: CategoryStatus,
        score: Int,
        showChevron: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(status.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Score
            Text("\(score)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(status.color)
            
            // Status badge
            Text(status.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.1))
                .cornerRadius(6)
            
            // Chevron for navigable items
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    // MARK: - View Tips Button
    
    private var viewTipsButton: some View {
        NavigationLink(value: MoreDestination.systemTips) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                
                Text("View Tips")
                    .font(AppFonts.bodyL)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppGradients.ctaGradient)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

struct DeviceHealthView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DeviceHealthView()
                .environmentObject(AppState.shared)
        }
    }
}
