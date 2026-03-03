import SwiftUI

// MARK: - Splash View
/// Стильный анимированный экран загрузки с эффектом заполнения текста

struct SplashView: View {
    
    // MARK: - Properties
    
    @State private var fillProgress: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    @State private var sparkles: [SplashSparkle] = []
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var showMainText: Bool = true
    @State private var mainTextOffset: CGFloat = 0
    @State private var mainTextOpacity: Double = 1
    @State private var taglineOffset: CGFloat = 30
    @State private var taglineOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    let onComplete: () -> Void
    
    private let animationDuration: Double = 8.0
    private let fillDuration: Double = 6.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundPrimary.opacity(0.95),
                    AppColors.accentBlue.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Sparkles layer (behind everything)
            ForEach(sparkles) { sparkle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [sparkle.color, sparkle.color.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: sparkle.size / 2
                        )
                    )
                    .frame(width: sparkle.size, height: sparkle.size)
                    .opacity(sparkle.opacity)
                    .offset(x: sparkle.x, y: sparkle.y)
            }
            
            // Main content - positioned slightly above center
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                Spacer()
                
                ZStack {
                    // Soft ambient glow
                    ambientGlow
                    
                    // Text container
                    ZStack {
                        // Main "Magic Swipe" text
                        liquidFilledText
                            .offset(y: mainTextOffset)
                            .opacity(mainTextOpacity)
                            .scaleEffect(pulseScale)
                        
                        // Tagline
                        Text("Making space for what matters")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accentPurple.opacity(0.9), AppColors.accentBlue.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(y: taglineOffset)
                            .opacity(taglineOpacity)
                    }
                }
                .frame(height: 100)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Ambient Glow
    
    private var ambientGlow: some View {
        ZStack {
            // Very soft, large glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.accentPurple.opacity(0.15),
                            AppColors.accentBlue.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 40)
        }
    }
    
    // MARK: - Liquid Filled Text
    
    private var liquidFilledText: some View {
        ZStack {
            // Background text (empty state) - very subtle
            Text("Magic Swipe")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppColors.textTertiary.opacity(0.2),
                            AppColors.textTertiary.opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Filled text with liquid mask
            Text("Magic Swipe")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    VStack(spacing: 0) {
                        // Empty space that shrinks as fill progresses
                        Color.clear
                            .frame(height: 80 * (1 - fillProgress))
                        
                        // Wave at the top of liquid
                        SplashWaveShape(phase: wavePhase, amplitude: 4 * min(fillProgress * 3, 1) * max(0, 1 - fillProgress))
                            .fill(Color.white)
                            .frame(height: 12)
                        
                        // Filled area
                        Rectangle()
                            .fill(Color.white)
                    }
                    .frame(height: 80)
                )
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Smooth glow appearance
        withAnimation(.easeOut(duration: 1.5)) {
            glowOpacity = 1.0
        }
        
        // Gentle glow breathing
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            glowScale = 1.1
        }
        
        // Continuous smooth wave animation
        startWaveAnimation()
        
        // Smooth liquid fill
        withAnimation(
            .easeInOut(duration: fillDuration)
        ) {
            fillProgress = 1.0
        }
        
        // Generate sparkles
        generateSparkles()
        
        // Pulse when fill completes
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pulseScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pulseScale = 1.0
                }
            }
        }
        
        // Transition to tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + fillDuration + 0.5) {
            transitionToTagline()
        }
        
        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            onComplete()
        }
    }
    
    private func startWaveAnimation() {
        // Use a display link style timer for smooth wave
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            wavePhase += 0.03
            
            if wavePhase > .pi * 100 {
                wavePhase = 0
            }
            
            // Stop after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                timer.invalidate()
            }
        }
    }
    
    private func transitionToTagline() {
        // Main text exits upward while fading
        withAnimation(.easeInOut(duration: 0.6)) {
            mainTextOffset = -20
            mainTextOpacity = 0
        }
        
        // Tagline enters from below
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            taglineOffset = 0
            taglineOpacity = 1
        }
    }
    
    private func generateSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            addSparkle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                timer.invalidate()
            }
        }
    }
    
    private func addSparkle() {
        let angle = Double.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 100...180)
        
        let sparkle = SplashSparkle(
            x: cos(angle) * distance,
            y: sin(angle) * distance * 0.4 - 20,
            size: CGFloat.random(in: 4...12),
            opacity: 0,
            color: [
                AppColors.accentPurple.opacity(0.6),
                AppColors.accentBlue.opacity(0.6),
                Color.white.opacity(0.4)
            ].randomElement()!
        )
        
        sparkles.append(sparkle)
        let sparkleId = sparkle.id
        
        // Fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let index = sparkles.firstIndex(where: { $0.id == sparkleId }) {
                withAnimation(.easeOut(duration: 0.4)) {
                    sparkles[index].opacity = Double.random(in: 0.3...0.7)
                }
            }
        }
        
        // Fade out and remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let index = sparkles.firstIndex(where: { $0.id == sparkleId }) {
                withAnimation(.easeOut(duration: 0.5)) {
                    sparkles[index].opacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                sparkles.removeAll { $0.id == sparkleId }
            }
        }
    }
}

// MARK: - Splash Wave Shape

struct SplashWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let midY = rect.height / 2
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: midY))
        
        // Draw wave
        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let y = midY + sin(relativeX * .pi * 2.5 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sparkle Model

struct SplashSparkle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var opacity: Double
    let color: Color
}

// MARK: - Preview

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onComplete: {})
    }
}
