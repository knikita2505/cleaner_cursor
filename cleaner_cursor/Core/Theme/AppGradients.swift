import SwiftUI

// MARK: - App Gradients
/// Градиенты приложения согласно ui_design.md

enum AppGradients {
    
    // MARK: - CTA Gradient (Primary)
    /// Используется для главных кнопок
    static let ctaGradient = LinearGradient(
        colors: [
            Color(hex: "3B5BFF"),
            Color(hex: "7A4DFB")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Aurora Gradient
    /// Используется для онбординга и paywalls
    static let auroraGradient = LinearGradient(
        colors: [
            Color(hex: "2F3DAF"),
            Color(hex: "6B3BDB"),
            Color(hex: "8B5CFF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Aurora Background
    /// Фоновый градиент для онбординга с затемнением снизу
    static let auroraBackground = LinearGradient(
        colors: [
            Color(hex: "2F3DAF").opacity(0.8),
            Color(hex: "6B3BDB").opacity(0.6),
            Color(hex: "8B5CFF").opacity(0.4),
            Color(hex: "0D0F16")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Progress Gradient
    /// Для storage indicators
    static let progressGradient = LinearGradient(
        colors: [
            Color(hex: "FF8D4D"),
            Color(hex: "FFD36B")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Card Gradient
    /// Легкий градиент для карточек
    static let cardGradient = LinearGradient(
        colors: [
            Color(hex: "111214"),
            Color(hex: "0D0F16")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Success Gradient
    static let successGradient = LinearGradient(
        colors: [
            Color(hex: "41D3B3"),
            Color(hex: "2BA88E")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Warning Gradient
    static let warningGradient = LinearGradient(
        colors: [
            Color(hex: "FFB84D"),
            Color(hex: "FF8D4D")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Gradient Shadow Modifier

struct GradientShadow: ViewModifier {
    let colors: [Color]
    let radius: CGFloat
    let opacity: Double
    
    init(
        colors: [Color] = [Color(hex: "3B5BFF"), Color(hex: "7A4DFB")],
        radius: CGFloat = 12,
        opacity: Double = 0.4
    ) {
        self.colors = colors
        self.radius = radius
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: colors.first?.opacity(opacity) ?? .clear, radius: radius, x: 0, y: 4)
    }
}

extension View {
    func gradientShadow(
        colors: [Color] = [Color(hex: "3B5BFF"), Color(hex: "7A4DFB")],
        radius: CGFloat = 12,
        opacity: Double = 0.4
    ) -> some View {
        modifier(GradientShadow(colors: colors, radius: radius, opacity: opacity))
    }
}

