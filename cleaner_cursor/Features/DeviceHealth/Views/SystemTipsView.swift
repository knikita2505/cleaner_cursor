import SwiftUI

// MARK: - System Tips View
/// Экран со списком системных советов по Storage, Battery, Performance

struct SystemTipsView: View {
    
    // MARK: - Properties
    
    @StateObject private var storageService = StorageService.shared
    @StateObject private var batteryService = BatteryService.shared
    @StateObject private var healthService = DeviceHealthService.shared
    @EnvironmentObject private var appState: AppState
    
    @State private var expandedTipId: String?
    @State private var selectedCategory: TipCategory = .all
    @State private var allTips: [SystemTip] = []
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Category Filter
                    categoryFilter
                    
                    // Tips List
                    tipsListView
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .navigationTitle("Tips & Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    refreshTips()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .onAppear {
            if allTips.isEmpty {
                refreshTips()
            }
        }
    }
    
    private func refreshTips() {
        healthService.refresh()
        allTips = generateTips()
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TipCategory.allCases, id: \.self) { category in
                    categoryChip(category)
                }
            }
        }
    }
    
    private func categoryChip(_ category: TipCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.title)
                    .font(AppFonts.subtitleM)
            }
            .foregroundColor(selectedCategory == category ? .white : AppColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                selectedCategory == category
                    ? AnyShapeStyle(AppGradients.ctaGradient)
                    : AnyShapeStyle(AppColors.backgroundSecondary)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tips List
    
    private var tipsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredTips) { tip in
                tipCard(tip)
            }
        }
    }
    
    private var filteredTips: [SystemTip] {
        switch selectedCategory {
        case .all:
            return allTips
        case .storage:
            return allTips.filter { $0.category == .storage }
        case .battery:
            return allTips.filter { $0.category == .battery }
        case .performance:
            return allTips.filter { $0.category == .performance }
        }
    }
    
    private func tipCard(_ tip: SystemTip) -> some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if expandedTipId == tip.id {
                        expandedTipId = nil
                    } else {
                        expandedTipId = tip.id
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(tip.category.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: tip.icon)
                            .font(.system(size: 20))
                            .foregroundColor(tip.category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(AppFonts.subtitleM)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(tip.category.title)
                            .font(AppFonts.caption)
                            .foregroundColor(tip.category.color)
                    }
                    
                    Spacer()
                    
                    Image(systemName: expandedTipId == tip.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.containerPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if expandedTipId == tip.id {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(AppColors.textTertiary.opacity(0.1))
                    
                    Text(tip.description)
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let action = tip.action {
                        Button {
                            handleTipAction(action)
                        } label: {
                            HStack(spacing: 8) {
                                Text(action.title)
                                    .font(AppFonts.subtitleM)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(tip.category.color)
                            .cornerRadius(10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.bottom, AppSpacing.containerPadding)
            }
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    // MARK: - Tips Generation
    
    private func generateTips() -> [SystemTip] {
        var tips: [SystemTip] = []
        
        // Storage tips - prioritize if storage is high
        let storageTips = generateStorageTips()
        let batteryTips = generateBatteryTips()
        let performanceTips = generatePerformanceTips()
        
        // Prioritize based on current state
        let usedPercentage = (storageService.storageInfo?.usagePercentage ?? 0) * 100
        if usedPercentage > 85 {
            tips.append(contentsOf: storageTips)
            tips.append(contentsOf: batteryTips)
            tips.append(contentsOf: performanceTips)
        } else if batteryService.batteryLevel < 0.3 {
            tips.append(contentsOf: batteryTips)
            tips.append(contentsOf: storageTips)
            tips.append(contentsOf: performanceTips)
        } else {
            // Interleave for variety
            let maxCount = max(storageTips.count, max(batteryTips.count, performanceTips.count))
            for i in 0..<maxCount {
                if i < storageTips.count { tips.append(storageTips[i]) }
                if i < batteryTips.count { tips.append(batteryTips[i]) }
                if i < performanceTips.count { tips.append(performanceTips[i]) }
            }
        }
        
        return tips
    }
    
    private func generateStorageTips() -> [SystemTip] {
        return [
            SystemTip(
                icon: "photo.on.rectangle.angled",
                title: "Review Similar Photos",
                description: "Similar photos take up extra space. Use our Similar Photos feature to find and remove duplicates while keeping the best shots.",
                category: .storage,
                action: TipAction(title: "Review Photos", destination: .similarPhotos)
            ),
            SystemTip(
                icon: "video.fill",
                title: "Check Large Videos",
                description: "Videos are often the biggest space consumers. Review large videos and consider moving them to cloud storage or deleting unused ones.",
                category: .storage,
                action: TipAction(title: "View Videos", destination: .videos)
            ),
            SystemTip(
                icon: "camera.viewfinder",
                title: "Clean Up Screenshots",
                description: "Old screenshots pile up quickly. Review and delete screenshots you no longer need to free up space.",
                category: .storage,
                action: TipAction(title: "Review Screenshots", destination: .screenshots)
            ),
            SystemTip(
                icon: "app.badge.fill",
                title: "Offload Unused Apps",
                description: "Enable 'Offload Unused Apps' in Settings to automatically remove apps you don't use while keeping their data.",
                category: .storage,
                action: TipAction(title: "Open Settings", destination: .settings)
            ),
            SystemTip(
                icon: "arrow.triangle.2.circlepath.icloud",
                title: "Use iCloud Photos",
                description: "Enable 'Optimize iPhone Storage' in Photos settings to store full-resolution photos in iCloud and keep smaller versions on your device.",
                category: .storage,
                action: nil
            ),
            SystemTip(
                icon: "message.fill",
                title: "Clear Message Attachments",
                description: "Messages can store large attachments. Go to Settings > General > iPhone Storage > Messages to review and delete large attachments.",
                category: .storage,
                action: nil
            )
        ]
    }
    
    private func generateBatteryTips() -> [SystemTip] {
        var tips: [SystemTip] = []
        
        tips.append(SystemTip(
            icon: "sun.max.fill",
            title: "Reduce Screen Brightness",
            description: "Screen brightness is one of the biggest battery drains. Use Auto-Brightness or manually reduce brightness to extend battery life significantly.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "location.slash.fill",
            title: "Limit Location Services",
            description: "Many apps use location in the background. Go to Settings > Privacy > Location Services and set apps to 'While Using' or 'Never' to save battery.",
            category: .battery,
            action: TipAction(title: "Open Settings", destination: .settings)
        ))
        
        if !batteryService.isLowPowerModeEnabled {
            tips.append(SystemTip(
                icon: "battery.25",
                title: "Enable Low Power Mode",
                description: "Low Power Mode reduces background activity, automatic downloads, and some visual effects. Enable it to extend battery life when you need it most.",
                category: .battery,
                action: nil
            ))
        }
        
        tips.append(SystemTip(
            icon: "app.badge.fill",
            title: "Disable Background App Refresh",
            description: "Apps refreshing in the background drain battery. Go to Settings > General > Background App Refresh and disable for apps that don't need it.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "envelope.fill",
            title: "Fetch Email Less Often",
            description: "Frequent email fetching uses battery. Change mail fetch settings to manual or hourly in Settings > Mail > Accounts > Fetch New Data.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "wifi.slash",
            title: "Turn Off Wi-Fi When Not Needed",
            description: "When you're not using Wi-Fi, your device constantly searches for networks. Disable Wi-Fi in areas with no networks to save battery.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "bolt.slash.fill",
            title: "Avoid Extreme Temperatures",
            description: "Extreme heat or cold can damage battery health. Keep your device between 16° and 22° C for optimal battery longevity.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "battery.100.bolt",
            title: "Don't Always Charge to 100%",
            description: "Regularly charging to 100% can reduce long-term battery capacity. Try to keep your battery between 20% and 80% for optimal health.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "antenna.radiowaves.left.and.right",
            title: "Use Wi-Fi Over Cellular",
            description: "Wi-Fi uses less power than cellular data. When available, connect to Wi-Fi to reduce battery consumption.",
            category: .battery,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "moon.fill",
            title: "Use Dark Mode",
            description: "On OLED screens (iPhone X and later), Dark Mode can significantly reduce battery usage since black pixels are turned off.",
            category: .battery,
            action: nil
        ))
        
        return tips
    }
    
    private func generatePerformanceTips() -> [SystemTip] {
        var tips: [SystemTip] = []
        
        if healthService.performanceScore < 80 {
            tips.append(SystemTip(
                icon: "arrow.clockwise",
                title: "Restart Your Device",
                description: "Your device has been running for \(healthService.uptimeDescription). Regular restarts clear temporary files and can improve performance.",
                category: .performance,
                action: nil
            ))
        }
        
        tips.append(SystemTip(
            icon: "arrow.down.app.fill",
            title: "Keep iOS Updated",
            description: "Apple regularly releases updates with performance improvements and bug fixes. Go to Settings > General > Software Update to check for updates.",
            category: .performance,
            action: TipAction(title: "Check Updates", destination: .settings)
        ))
        
        tips.append(SystemTip(
            icon: "xmark.app.fill",
            title: "Close Unused Apps",
            description: "While iOS manages memory well, closing apps you're not using can free up resources for the apps you need.",
            category: .performance,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "safari.fill",
            title: "Clear Safari Data",
            description: "Clearing Safari's history and website data can speed up browsing. Go to Settings > Safari > Clear History and Website Data.",
            category: .performance,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "square.stack.3d.up.fill",
            title: "Reduce Motion Effects",
            description: "Reduce motion effects to improve performance on older devices. Go to Settings > Accessibility > Motion > Reduce Motion.",
            category: .performance,
            action: nil
        ))
        
        tips.append(SystemTip(
            icon: "sparkles",
            title: "Disable Siri Suggestions",
            description: "Siri Suggestions analyze your usage patterns. Disabling them can reduce background processing. Find this in Settings > Siri & Search.",
            category: .performance,
            action: nil
        ))
        
        return tips
    }
    
    // MARK: - Actions
    
    private func handleTipAction(_ action: TipAction) {
        switch action.destination {
        case .similarPhotos:
            appState.selectedTab = .clean
        case .videos:
            appState.selectedTab = .clean
        case .screenshots:
            appState.selectedTab = .clean
        case .settings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .dashboard:
            appState.selectedTab = .clean
        }
    }
}

// MARK: - Tip Category

enum TipCategory: CaseIterable {
    case all
    case storage
    case battery
    case performance
    
    var title: String {
        switch self {
        case .all: return "All"
        case .storage: return "Storage"
        case .battery: return "Battery"
        case .performance: return "Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .storage: return "internaldrive"
        case .battery: return "battery.75"
        case .performance: return "speedometer"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return AppColors.accentBlue
        case .storage: return AppColors.accentPurple
        case .battery: return AppColors.statusSuccess
        case .performance: return AppColors.statusWarning
        }
    }
}

// MARK: - System Tip Model

struct SystemTip: Identifiable {
    let id = UUID().uuidString
    let icon: String
    let title: String
    let description: String
    let category: TipCategory
    let action: TipAction?
}

// MARK: - Tip Action

struct TipAction {
    let title: String
    let destination: TipDestination
}

enum TipDestination {
    case similarPhotos
    case videos
    case screenshots
    case settings
    case dashboard
}

// MARK: - Preview

struct SystemTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SystemTipsView()
                .environmentObject(AppState.shared)
        }
    }
}
