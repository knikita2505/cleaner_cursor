import SwiftUI

// MARK: - App Spacing
/// Отступы и размеры согласно ui_design.md

enum AppSpacing {
    
    // MARK: - Padding
    
    /// Внешние отступы экрана
    static let screenPadding: CGFloat = 20
    
    /// Большие внешние отступы
    static let screenPaddingLarge: CGFloat = 24
    
    /// Внутренние отступы в контейнерах
    static let containerPadding: CGFloat = 16
    
    /// Большие внутренние отступы
    static let containerPaddingLarge: CGFloat = 20
    
    /// Между блоками
    static let blockSpacing: CGFloat = 16
    
    /// Между иконкой и текстом
    static let iconTextSpacing: CGFloat = 12
    
    // MARK: - Corner Radius
    
    /// Карточки
    static let cardRadius: CGFloat = 20
    
    /// Кнопки
    static let buttonRadius: CGFloat = 16
    
    /// Большой радиус кнопок
    static let buttonRadiusLarge: CGFloat = 20
    
    /// Модальные окна
    static let modalRadius: CGFloat = 32
    
    /// Прогресс-бар
    static let progressRadius: CGFloat = 4
    
    // MARK: - Component Sizes
    
    /// Высота primary кнопки
    static let buttonHeight: CGFloat = 56
    
    /// Высота secondary кнопки
    static let buttonHeightSecondary: CGFloat = 48
    
    /// Высота строки списка
    static let listRowHeight: CGFloat = 72
    
    /// Большая высота строки списка
    static let listRowHeightLarge: CGFloat = 80
    
    /// Высота прогресс-бара
    static let progressBarHeight: CGFloat = 8
    
    // MARK: - Icon Sizes
    
    /// Маленькая иконка
    static let iconSmall: CGFloat = 24
    
    /// Средняя иконка
    static let iconMedium: CGFloat = 32
    
    /// Большая иконка в списке
    static let iconLarge: CGFloat = 36
    
    /// Очень большая иконка
    static let iconXLarge: CGFloat = 44
    
    /// Иконка permission экрана
    static let iconPermission: CGFloat = 80
    
    // MARK: - Illustration Sizes
    
    /// Размер иллюстрации на онбординге
    static let illustrationSize: CGFloat = 200
}

// MARK: - Shadow Configuration

enum AppShadow {
    /// Мягкая тень для карточек
    static let soft = (color: Color.black.opacity(0.3), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    
    /// Средняя тень
    static let medium = (color: Color.black.opacity(0.4), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
}

