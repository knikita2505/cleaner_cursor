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
                VStack(spacing: 24) {
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
        VStack(spacing: 20) {
            // Score Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        AppColors.textTertiary.opacity(0.2),
                        lineWidth: 12
                    )
                    .frame(width: 140, height: 140)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(healthService.healthScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: healthGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: healthService.healthScore)
                
                // Score text
                VStack(spacing: 4) {
                    Text("\(healthService.healthScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(healthService.healthStatus.color)
                    
                    Text("Health Score")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Status badge
            HStack(spacing: 8) {
                Image(systemName: healthService.healthStatus.icon)
                    .font(.system(size: 16))
                
                Text(healthService.healthStatus.title)
                    .font(AppFonts.subtitleM)
            }
            .foregroundColor(healthService.healthStatus.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(healthService.healthStatus.color.opacity(0.15))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
                .padding(.leading, 60)
            
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
                .padding(.leading, 60)
            
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
                .padding(.leading, 60)
            
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
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(status.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
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
        .padding(AppSpacing.containerPadding)
        .contentShape(Rectangle())
        .padding(AppSpacing.containerPadding)
    }
    
    // MARK: - View Tips Button
    
    private var viewTipsButton: some View {
        NavigationLink(value: MoreDestination.systemTips) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                
                Text("View Tips")
                    .font(AppFonts.subtitleM)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding(AppSpacing.containerPadding)
            .background(AppGradients.ctaGradient)
            .cornerRadius(AppSpacing.cardRadius)
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
