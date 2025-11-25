import SwiftUI

// MARK: - App Router
/// Координатор навигации приложения

@MainActor
final class Router: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var path = NavigationPath()
    @Published var presentedSheet: Sheet?
    @Published var presentedFullScreenCover: FullScreenCover?
    
    // MARK: - Singleton
    
    static let shared = Router()
    
    private init() {}
    
    // MARK: - Navigation
    
    func push<T: Hashable>(_ destination: T) {
        path.append(destination)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    // MARK: - Sheets
    
    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    // MARK: - Full Screen Covers
    
    func presentFullScreen(_ cover: FullScreenCover) {
        presentedFullScreenCover = cover
    }
    
    func dismissFullScreen() {
        presentedFullScreenCover = nil
    }
}

// MARK: - Sheet Types

enum Sheet: Identifiable {
    case settings
    case paywall
    case photoDetail(asset: Any)
    case videoDetail(asset: Any)
    case contactDetail(contact: Any)
    
    var id: String {
        switch self {
        case .settings: return "settings"
        case .paywall: return "paywall"
        case .photoDetail: return "photoDetail"
        case .videoDetail: return "videoDetail"
        case .contactDetail: return "contactDetail"
        }
    }
}

// MARK: - Full Screen Cover Types

enum FullScreenCover: Identifiable {
    case onboarding
    case secretFolderAuth
    case swipeClean
    case chargingAnimation
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .secretFolderAuth: return "secretFolderAuth"
        case .swipeClean: return "swipeClean"
        case .chargingAnimation: return "chargingAnimation"
        }
    }
}

// MARK: - Navigation View Modifier

struct NavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .photosCleaner:
                    Text("Photos Cleaner") // Placeholder
                case .videosCleaner:
                    Text("Videos Cleaner") // Placeholder
                case .contactsCleaner:
                    Text("Contacts Cleaner") // Placeholder
                case .emailCleaner:
                    Text("Email Cleaner") // Placeholder
                case .secretFolder:
                    Text("Secret Folder") // Placeholder
                case .storageOverview:
                    Text("Storage Overview") // Placeholder
                case .battery:
                    Text("Battery") // Placeholder
                }
            }
            .navigationDestination(for: PhotosDestination.self) { destination in
                switch destination {
                case .duplicates:
                    Text("Duplicates") // Placeholder
                case .similar:
                    Text("Similar Photos") // Placeholder
                case .screenshots:
                    Text("Screenshots") // Placeholder
                case .livePhotos:
                    Text("Live Photos") // Placeholder
                case .burst:
                    Text("Burst Photos") // Placeholder
                case .bigFiles:
                    Text("Big Files") // Placeholder
                case .swipeClean:
                    Text("Swipe Clean") // Placeholder
                }
            }
    }
}

extension View {
    func withNavigationDestinations() -> some View {
        modifier(NavigationDestinationModifier())
    }
}

