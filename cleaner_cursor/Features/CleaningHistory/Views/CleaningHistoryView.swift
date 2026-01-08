import SwiftUI

// MARK: - Cleaning History View
/// Экран истории очисток с графиками и статистикой

struct CleaningHistoryView: View {
    
    // MARK: - Properties
    
    @StateObject private var historyService = CleaningHistoryService.shared
    @EnvironmentObject private var appState: AppState
    @State private var showClearConfirmation = false
    @State private var hasAppeared: Bool = false
    @State private var showFeatureTip: Bool = false
    
    private let tipService = FeatureTipService.shared
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Summary
                    todaySummaryCard
                    
                    // Weekly Graph
                    weeklyGraphCard
                    
                    // Monthly Summary with Pie Chart
                    monthlySummaryCard
                    
                    // Recommendations
                    recommendationsSection
                    
                    // CTA Button
                    startCleaningButton
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .navigationTitle("Cleaning History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.statusError)
                }
            }
        }
        .alert("Clear History", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                historyService.clearAllHistory()
                HapticManager.success()
            }
        } message: {
            Text("This will permanently delete all cleaning history from your device.")
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Show feature tip on first visit
            if tipService.shouldShowTip(for: .cleaningHistory) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFeatureTip = true
                }
            }
        }
        .fullScreenCover(isPresented: $showFeatureTip) {
            FeatureTipView(tipData: .cleaningHistory) {
                tipService.markTipAsShown(for: .cleaningHistory)
                showFeatureTip = false
            }
        }
    }
    
    // MARK: - Today's Summary Card
    
    private var todaySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(formattedDate(Date()))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            HStack(spacing: 20) {
                summaryStatView(
                    value: historyService.todaySummary.formattedBytes,
                    label: "Freed",
                    icon: "arrow.up.trash.fill",
                    color: AppColors.statusSuccess
                )
                
                Divider()
                    .frame(height: 40)
                
                summaryStatView(
                    value: "\(historyService.todaySummary.itemsCount)",
                    label: "Items",
                    icon: "doc.fill",
                    color: AppColors.accentBlue
                )
                
                Divider()
                    .frame(height: 40)
                
                summaryStatView(
                    value: "\(historyService.todaySummary.sessionsCount)",
                    label: "Sessions",
                    icon: "clock.fill",
                    color: AppColors.accentPurple
                )
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func summaryStatView(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Weekly Graph Card
    
    private var weeklyGraphCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(historyService.weeklySummary.formattedBytes)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            // Bar Chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(historyService.weeklyData) { day in
                    weeklyBarView(day: day)
                }
            }
            .frame(height: 120)
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func weeklyBarView(day: DailyCleaningData) -> some View {
        let maxBytes = historyService.weeklyData.map { $0.bytesFreed }.max() ?? 1
        let normalizedHeight = maxBytes > 0 ? CGFloat(day.bytesFreed) / CGFloat(maxBytes) : 0
        let isToday = Calendar.current.isDateInToday(day.date)
        
        return VStack(spacing: 6) {
            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isToday
                        ? LinearGradient(colors: [AppColors.accentBlue, AppColors.accentPurple], startPoint: .bottom, endPoint: .top)
                        : LinearGradient(colors: [AppColors.textTertiary.opacity(0.3), AppColors.textTertiary.opacity(0.5)], startPoint: .bottom, endPoint: .top)
                )
                .frame(height: max(4, normalizedHeight * 80))
            
            // Day label
            Text(day.dayName)
                .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? AppColors.accentBlue : AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Monthly Summary Card
    
    private var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Month")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(historyService.monthlySummary.formattedBytes)
                    .font(AppFonts.subtitleM)
                    .foregroundColor(AppColors.statusSuccess)
            }
            
            HStack(spacing: 16) {
                // Pie Chart
                pieChartView
                    .frame(width: 100, height: 100)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    let segments = historyService.getPieChartData().prefix(4)
                    ForEach(segments) { segment in
                        legendRow(segment: segment)
                    }
                    
                    if historyService.getPieChartData().isEmpty {
                        Text("No data yet")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Stats row
            HStack(spacing: 16) {
                statBadge(
                    value: "\(historyService.monthlySummary.itemsCount)",
                    label: "items cleaned"
                )
                
                statBadge(
                    value: "\(historyService.monthlySummary.sessionsCount)",
                    label: "cleaning sessions"
                )
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private var pieChartView: some View {
        let segments = historyService.getPieChartData()
        
        return ZStack {
            if segments.isEmpty {
                Circle()
                    .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 12)
            } else {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let startAngle = segments.prefix(index).reduce(0.0) { $0 + $1.percentage }
                    
                    Circle()
                        .trim(from: startAngle, to: startAngle + segment.percentage)
                        .stroke(segment.type.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(spacing: 2) {
                Text(historyService.monthlySummary.formattedBytes)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("total")
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
    
    private func legendRow(segment: PieChartSegment) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(segment.type.color)
                .frame(width: 8, height: 8)
            
            Text(segment.type.displayName)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(formatPercentage(segment.percentage))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    private func statBadge(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.backgroundPrimary)
        .cornerRadius(8)
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(AppFonts.subtitleL)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(historyService.getRecommendations().prefix(3)) { recommendation in
                    recommendationCard(recommendation)
                }
            }
        }
    }
    
    private func recommendationCard(_ recommendation: CleaningRecommendation) -> some View {
        Button {
            handleRecommendationTap(recommendation)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recommendation.priority.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: recommendation.icon)
                        .font(.system(size: 18))
                        .foregroundColor(recommendation.priority.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(AppFonts.subtitleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(recommendation.description)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if recommendation.type != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary.opacity(0.5))
                }
            }
            .padding(12)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(recommendation.type == nil)
    }
    
    // MARK: - Start Cleaning Button
    
    private var startCleaningButton: some View {
        Button {
            appState.selectedTab = .clean
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                
                Text("Start Cleaning Now")
                    .font(AppFonts.subtitleM)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppGradients.ctaGradient)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatPercentage(_ percentage: Double) -> String {
        let percent = percentage * 100
        if percent < 1 {
            return "<1%"
        }
        return "\(Int(percent))%"
    }
    
    private func handleRecommendationTap(_ recommendation: CleaningRecommendation) {
        guard recommendation.type != nil else { return }
        appState.selectedTab = .clean
    }
}

// MARK: - Preview

struct CleaningHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CleaningHistoryView()
                .environmentObject(AppState.shared)
        }
    }
}

