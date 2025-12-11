import SwiftUI

// MARK: - App Colors
/// Цветовая палитра приложения согласно ui_design.md

enum AppColors {
    
    // MARK: - Background Colors
    
    /// Глубокий тёмный синий - основной фон
    static let backgroundPrimary = Color(hex: "0D0F16")
    
    /// Графитовый - для рабочих экранов
    static let backgroundSecondary = Color(hex: "111214")
    
    /// Фон для карточек списка
    static let backgroundCard = Color(hex: "121317")
    
    /// Фон модальных окон
    static let backgroundModal = Color(hex: "0F1116")
    
    // MARK: - Accent Colors
    
    /// Основной синий
    static let accentBlue = Color(hex: "3B5BFF")
    
    /// Фиолетовый
    static let accentPurple = Color(hex: "7A4DFB")
    
    /// Сиреневый светлый
    static let accentLilac = Color(hex: "A88CFF")
    
    /// Голубое свечение
    static let accentGlow = Color(hex: "7FB9FF")
    
    // MARK: - Text Colors
    
    /// Основной текст (bold headers)
    static let textPrimary = Color.white
    
    /// Вторичный текст (описания)
    static let textSecondary = Color(hex: "E6E8ED")
    
    /// Третичный текст (системные)
    static let textTertiary = Color(hex: "AEB4BE")
    
    // MARK: - Status Colors
    
    /// Успех
    static let statusSuccess = Color(hex: "41D3B3")
    
    /// Предупреждение
    static let statusWarning = Color(hex: "FFB84D")
    
    /// Ошибка
    static let statusError = Color(hex: "FF4D4D")
    
    // MARK: - Progress Bar Colors
    
    /// Начало градиента прогресс-бара
    static let progressStart = Color(hex: "FF8D4D")
    
    /// Конец градиента прогресс-бара
    static let progressEnd = Color(hex: "FFD36B")
    
    /// Неактивный прогресс-бар
    static let progressInactive = Color.white.opacity(0.1)
    
    // MARK: - Border Colors
    
    /// Граница secondary кнопки
    static let borderSecondary = Color.white.opacity(0.2)
    
    // MARK: - Dashboard Colors
    
    /// Неоновый синий для Used показателей
    static let neonBlue = Color(hex: "5555FF")
    
    /// Неоновый розовый для Clutter показателей
    static let neonPink = Color(hex: "FE019A")
    
    /// Золотисто-желтый для Premium
    static let premiumGold = Color(hex: "FFD700")
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

