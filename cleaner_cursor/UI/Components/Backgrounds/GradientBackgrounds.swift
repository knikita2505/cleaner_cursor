import SwiftUI

// MARK: - Aurora Background
/// Фоновый градиент для онбординга и paywall

struct AuroraBackground: View {
    let animated: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    init(animated: Bool = false) {
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // Base dark color
            AppColors.backgroundPrimary
            
            // Aurora gradient circles
            GeometryReader { geometry in
                ZStack {
                    // Top left aurora
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "6B3BDB").opacity(0.6),
                                    Color(hex: "6B3BDB").opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.6
                            )
                        )
                        .frame(width: geometry.size.width * 1.2)
                        .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.2)
                        .offset(x: animated ? sin(animationPhase) * 20 : 0)
                    
                    // Top right aurora
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "3B5BFF").opacity(0.4),
                                    Color(hex: "3B5BFF").opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.5
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: geometry.size.width * 0.4, y: -geometry.size.height * 0.1)
                        .offset(x: animated ? -sin(animationPhase) * 15 : 0)
                    
                    // Center aurora
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8B5CFF").opacity(0.3),
                                    Color(hex: "8B5CFF").opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.7
                            )
                        )
                        .frame(width: geometry.size.width * 1.0)
                        .offset(y: -geometry.size.height * 0.15)
                        .offset(y: animated ? cos(animationPhase) * 10 : 0)
                }
            }
            
            // Bottom fade to dark
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        AppColors.backgroundPrimary.opacity(0),
                        AppColors.backgroundPrimary.opacity(0.8),
                        AppColors.backgroundPrimary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animationPhase = .pi * 2
                }
            }
        }
    }
}

// MARK: - Dark Gradient Background
/// Простой тёмный градиентный фон

struct DarkGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppColors.backgroundSecondary,
                AppColors.backgroundPrimary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mesh Gradient Background (iOS 18+)
/// Современный mesh-градиент для премиум экранов

struct MeshBackground: View {
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
            
            GeometryReader { geometry in
                ZStack {
                    // Multiple gradient layers
                    EllipticalGradient(
                        colors: [
                            Color(hex: "3B5BFF").opacity(0.3),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.8
                    )
                    
                    EllipticalGradient(
                        colors: [
                            Color(hex: "7A4DFB").opacity(0.25),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.6
                    )
                    
                    EllipticalGradient(
                        colors: [
                            Color(hex: "6B3BDB").opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.7
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Particle Background
/// Фон с частицами для charging animations

struct ParticleBackground: View {
    @State private var particles: [Particle] = []
    let particleCount: Int
    let color: Color
    
    init(particleCount: Int = 30, color: Color = AppColors.accentBlue) {
        self.particleCount = particleCount
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.backgroundPrimary
                
                ForEach(particles) { particle in
                    Circle()
                        .fill(color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.blur)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.1...0.4),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.y -= CGFloat.random(in: 0.5...1.5)
                particles[i].position.x += CGFloat.random(in: -0.5...0.5)
                
                if particles[i].position.y < -10 {
                    particles[i].position.y = size.height + 10
                    particles[i].position.x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Preview

struct GradientBackgrounds_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AuroraBackground(animated: true)
                .previewDisplayName("Aurora Background")
            
            DarkGradientBackground()
                .previewDisplayName("Dark Gradient")
            
            MeshBackground()
                .previewDisplayName("Mesh Background")
        }
    }
}

