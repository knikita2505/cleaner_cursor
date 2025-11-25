import SwiftUI

// MARK: - View Extensions

extension View {
    
    // MARK: - Conditional Modifier
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // MARK: - Hide Keyboard
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Card Style
    
    func cardStyle() -> some View {
        self
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.cardRadius)
            .shadow(color: AppShadow.soft.color, radius: AppShadow.soft.radius, x: AppShadow.soft.x, y: AppShadow.soft.y)
    }
    
    // MARK: - Read Size
    
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// MARK: - Size Preference Key

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Fade Edge Modifier

struct FadeEdgeModifier: ViewModifier {
    let edge: Edge
    let length: CGFloat
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: length / 100),
                        .init(color: .black, location: 1 - length / 100),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: edge == .top || edge == .leading ? .top : .bottom,
                    endPoint: edge == .top || edge == .leading ? .bottom : .top
                )
            )
    }
}

extension View {
    func fadeEdge(_ edge: Edge, length: CGFloat = 20) -> some View {
        modifier(FadeEdgeModifier(edge: edge, length: length))
    }
}

