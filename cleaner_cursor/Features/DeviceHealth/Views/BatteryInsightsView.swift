import SwiftUI

// MARK: - Battery Insights View
/// Экран с детальной информацией о батарее и анимацией зарядки

struct BatteryInsightsView: View {
    
    // MARK: - Properties
    
    @StateObject private var batteryService = BatteryService.shared
    @State private var waveOffset: CGFloat = 0
    @State private var showHighChargeWarning = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Battery Animation Card
                    batteryAnimationCard
                    
                    // Battery Stats
                    batteryStatsSection
                    
                    // Tips
                    tipsSection
                    
                    // Check in Settings
                    settingsInfoCard
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .navigationTitle("Battery Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startWaveAnimation()
            checkHighCharge()
        }
    }
    
    // MARK: - Battery Animation Card
    
    private var batteryAnimationCard: some View {
        VStack(spacing: 20) {
            // Animated Battery
            ZStack {
                // Battery outline
                BatteryShape()
                    .stroke(batteryColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 120, height: 200)
                
                // Battery fill with wave
                BatteryShape()
                    .fill(Color.clear)
                    .frame(width: 120, height: 200)
                    .overlay {
                        GeometryReader { geo in
                            let fillHeight = geo.size.height * CGFloat(batteryService.batteryLevel)
                            
                            ZStack(alignment: .bottom) {
                                // Wave effect
                                WaveShape(offset: waveOffset, percent: Double(batteryService.batteryLevel))
                                    .fill(
                                        LinearGradient(
                                            colors: [batteryColor, batteryColor.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: fillHeight + 20)
                            }
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .clipShape(BatteryShape())
                    }
                
                // Battery cap
                RoundedRectangle(cornerRadius: 4)
                    .fill(batteryColor.opacity(0.5))
                    .frame(width: 40, height: 12)
                    .offset(y: -106)
                
                // Percentage text
                VStack(spacing: 4) {
                    Text("\(batteryService.batteryPercentage)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if batteryService.isCharging {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                            Text("Charging")
                                .font(AppFonts.caption)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(height: 220)
            
            // State description
            HStack(spacing: 8) {
                Image(systemName: batteryService.isCharging ? "bolt.circle.fill" : "battery.100")
                    .font(.system(size: 18))
                
                Text(batteryService.batteryStateDescription)
                    .font(AppFonts.subtitleM)
            }
            .foregroundColor(batteryColor)
            
            // High charge warning
            if showHighChargeWarning {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                    
                    Text("Try not to charge to 100% every time")
                        .font(AppFonts.caption)
                }
                .foregroundColor(AppColors.statusWarning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.statusWarning.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private var batteryColor: Color {
        if batteryService.batteryLevel >= 0.5 {
            return AppColors.statusSuccess
        } else if batteryService.batteryLevel >= 0.2 {
            return AppColors.statusWarning
        } else {
            return AppColors.statusError
        }
    }
    
    // MARK: - Battery Stats Section
    
    private var batteryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Stats")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 2) {
                statRow(
                    icon: "battery.100",
                    title: "Current Level",
                    value: "\(batteryService.batteryPercentage)%",
                    color: batteryColor
                )
                
                Divider()
                    .background(AppColors.textTertiary.opacity(0.1))
                    .padding(.leading, 52)
                
                statRow(
                    icon: batteryService.isCharging ? "bolt.fill" : "powerplug.fill",
                    title: "Status",
                    value: batteryService.batteryStateDescription,
                    color: batteryService.isCharging ? AppColors.statusSuccess : AppColors.textSecondary
                )
                
                Divider()
                    .background(AppColors.textTertiary.opacity(0.1))
                    .padding(.leading, 52)
                
                statRow(
                    icon: "leaf.fill",
                    title: "Low Power Mode",
                    value: batteryService.isLowPowerModeEnabled ? "On" : "Off",
                    color: batteryService.isLowPowerModeEnabled ? AppColors.statusSuccess : AppColors.textSecondary
                )
            }
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
    }
    
    private func statRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(AppFonts.bodyM)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.subtitleM)
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Tips")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(batteryService.batteryTips.prefix(5)) { tip in
                    tipCard(tip)
                }
            }
        }
    }
    
    private func tipCard(_ tip: BatteryTip) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: tip.icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(tip.description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Settings Info Card
    
    private var settingsInfoCard: some View {
        Button {
            openBatterySettings()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.accentPurple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Battery Health & Charging")
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Check detailed info in Settings")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.accentPurple)
            }
            .padding(AppSpacing.containerPadding)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
    
    // MARK: - Actions
    
    private func startWaveAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            waveOffset = .pi * 2
        }
    }
    
    private func checkHighCharge() {
        showHighChargeWarning = batteryService.batteryLevel > 0.8 && batteryService.isCharging
    }
    
    private func openBatterySettings() {
        if let url = URL(string: "App-prefs:BATTERY_USAGE") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Battery Shape

struct BatteryShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 16
        let bodyRect = CGRect(x: rect.minX, y: rect.minY + 12, width: rect.width, height: rect.height - 12)
        
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        return path
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var offset: CGFloat
    var percent: Double
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 8
        let startY = rect.minY + waveHeight
        
        path.move(to: CGPoint(x: 0, y: startY))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset)
            let y = startY + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview

struct BatteryInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BatteryInsightsView()
        }
    }
}
