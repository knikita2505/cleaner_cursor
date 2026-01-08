import SwiftUI

// MARK: - Splash View
/// Анимированный экран загрузки приложения

struct SplashView: View {
    
    // MARK: - Properties
    
    @State private var gearRotation: Double = 0
    @State private var sparkles: [SparkleParticle] = []
    @State private var dustParticles: [DustParticle] = []
    @State private var showText = false
    @State private var textOpacity: Double = 0
    @State private var progressWidth: CGFloat = 0
    
    let onComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundPrimary.opacity(0.95),
                    AppColors.accentBlue.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated broom with sparkles
                ZStack {
                    // Dust particles
                    ForEach(dustParticles) { particle in
                        Circle()
                            .fill(AppColors.textTertiary.opacity(particle.opacity))
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                    }
                    
                    // Sparkles
                    ForEach(sparkles) { sparkle in
                        Image(systemName: "sparkle")
                            .font(.system(size: sparkle.size))
                            .foregroundColor(sparkle.color)
                            .opacity(sparkle.opacity)
                            .offset(x: sparkle.x, y: sparkle.y)
                            .rotationEffect(.degrees(sparkle.rotation))
                    }
                    
                    // Gear icon
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppColors.accentBlue.opacity(0.4), AppColors.accentPurple.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                        
                        // Main icon - spinning gear
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accentBlue, AppColors.accentPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(gearRotation))
                    }
                }
                .frame(height: 180)
                
                // App name and tagline
                VStack(spacing: 12) {
                    Text("Cleaner")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Making space for what matters")
                        .font(AppFonts.bodyM)
                        .foregroundColor(AppColors.textTertiary)
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Progress bar
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.backgroundSecondary)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.accentBlue, AppColors.accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressWidth, height: 6)
                    }
                    .frame(width: 200)
                    
                    Text("Preparing...")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .opacity(textOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Gear spinning animation
        withAnimation(
            .linear(duration: 3.0)
            .repeatForever(autoreverses: false)
        ) {
            gearRotation = 360
        }
        
        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            textOpacity = 1
            showText = true
        }
        
        // Progress bar animation
        withAnimation(.easeInOut(duration: 6.0)) {
            progressWidth = 200
        }
        
        // Generate sparkles
        generateSparkles()
        
        // Generate dust particles
        generateDustParticles()
        
        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                onComplete()
            }
        }
    }
    
    private func generateSparkles() {
        // Create initial sparkles
        for i in 0..<8 {
            let delay = Double(i) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                addSparkle()
            }
        }
        
        // Continue generating sparkles
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if sparkles.count < 12 {
                addSparkle()
            }
            
            // Stop after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                timer.invalidate()
            }
        }
    }
    
    private func addSparkle() {
        let sparkle = SparkleParticle(
            x: CGFloat.random(in: -80...80),
            y: CGFloat.random(in: -60...60),
            size: CGFloat.random(in: 8...16),
            opacity: Double.random(in: 0.4...1.0),
            rotation: Double.random(in: 0...360),
            color: [AppColors.accentBlue, AppColors.accentPurple, AppColors.accentGlow].randomElement()!
        )
        
        withAnimation(.easeOut(duration: 0.3)) {
            sparkles.append(sparkle)
        }
        
        // Remove sparkle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
    
    private func generateDustParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let particle = DustParticle(
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: 20...80),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.2...0.5)
            )
            
            withAnimation(.easeOut(duration: 0.5)) {
                dustParticles.append(particle)
            }
            
            // Remove particle after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    dustParticles.removeAll { $0.id == particle.id }
                }
            }
            
            // Stop after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Particle Models

struct SparkleParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let rotation: Double
    let color: Color
}

struct DustParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

// MARK: - Preview

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onComplete: {})
    }
}
