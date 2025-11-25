import SwiftUI

// MARK: - Storage Progress Bar
/// Прогресс-бар для отображения использования хранилища
/// Height: 8pt, Radius: full, Gradient: #FF8D4D → #FFD36B

struct StorageProgressBar: View {
    let progress: Double // 0.0 - 1.0
    let height: CGFloat
    let showPercentage: Bool
    
    init(
        progress: Double,
        height: CGFloat = AppSpacing.progressBarHeight,
        showPercentage: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(AppColors.progressInactive)
                        .frame(height: height)
                    
                    // Progress
                    Capsule()
                        .fill(AppGradients.progressGradient)
                        .frame(width: geometry.size.width * progress, height: height)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - Accent Progress Bar
/// Прогресс-бар с акцентным цветом (синий/фиолетовый)

struct AccentProgressBar: View {
    let progress: Double
    let accentColor: Color
    let height: CGFloat
    
    init(
        progress: Double,
        accentColor: Color = AppColors.accentBlue,
        height: CGFloat = AppSpacing.progressBarHeight
    ) {
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(AppColors.progressInactive)
                    .frame(height: height)
                
                // Progress
                Capsule()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Circular Progress
/// Круговой индикатор прогресса

struct CircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let showPercentage: Bool
    let gradient: LinearGradient
    
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 100,
        showPercentage: Bool = true,
        gradient: LinearGradient = AppGradients.ctaGradient
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
        self.gradient = gradient
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(AppColors.progressInactive, lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.titleM)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Segmented Progress
/// Сегментированный прогресс (для онбординга)

struct SegmentedProgress: View {
    let totalSegments: Int
    let currentSegment: Int
    let activeColor: Color
    let inactiveColor: Color
    let spacing: CGFloat
    let height: CGFloat
    
    init(
        totalSegments: Int,
        currentSegment: Int,
        activeColor: Color = AppColors.accentBlue,
        inactiveColor: Color = AppColors.progressInactive,
        spacing: CGFloat = 8,
        height: CGFloat = 4
    ) {
        self.totalSegments = totalSegments
        self.currentSegment = currentSegment
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.spacing = spacing
        self.height = height
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSegments, id: \.self) { index in
                Capsule()
                    .fill(index <= currentSegment ? activeColor : inactiveColor)
                    .frame(height: height)
                    .animation(.easeOut(duration: 0.25), value: currentSegment)
            }
        }
    }
}

// MARK: - Dot Progress
/// Точечный индикатор (для пагинации)

struct DotProgress: View {
    let totalDots: Int
    let currentIndex: Int
    let activeColor: Color
    let inactiveColor: Color
    let dotSize: CGFloat
    let spacing: CGFloat
    
    init(
        totalDots: Int,
        currentIndex: Int,
        activeColor: Color = AppColors.accentBlue,
        inactiveColor: Color = AppColors.progressInactive,
        dotSize: CGFloat = 8,
        spacing: CGFloat = 8
    ) {
        self.totalDots = totalDots
        self.currentIndex = currentIndex
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.dotSize = dotSize
        self.spacing = spacing
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalDots, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? activeColor : inactiveColor)
                    .frame(width: index == currentIndex ? dotSize * 1.5 : dotSize, height: dotSize)
                    .animation(.easeOut(duration: 0.25), value: currentIndex)
            }
        }
    }
}

// MARK: - Preview

struct ProgressBars_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage Progress")
                        .foregroundColor(AppColors.textSecondary)
                    StorageProgressBar(progress: 0.75, showPercentage: true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accent Progress")
                        .foregroundColor(AppColors.textSecondary)
                    AccentProgressBar(progress: 0.6, accentColor: AppColors.accentPurple)
                }
                
                HStack(spacing: 32) {
                    CircularProgress(progress: 0.75, size: 80)
                    CircularProgress(
                        progress: 0.45,
                        size: 80,
                        gradient: AppGradients.progressGradient
                    )
                }
                
                VStack(spacing: 16) {
                    SegmentedProgress(totalSegments: 4, currentSegment: 2)
                    DotProgress(totalDots: 4, currentIndex: 1)
                }
            }
            .padding()
        }
    }
}

