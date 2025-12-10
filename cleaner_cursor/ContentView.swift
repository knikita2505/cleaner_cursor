import SwiftUI

// MARK: - Content View
/// Основной контент view (используется для совместимости)
/// Реальная логика находится в RootView

struct ContentView: View {
    var body: some View {
        RootView()
            .environmentObject(AppState.shared)
            .environmentObject(SubscriptionService.shared)
            }
        }

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
