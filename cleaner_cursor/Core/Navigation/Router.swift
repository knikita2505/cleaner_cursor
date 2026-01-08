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

// MARK: - More Destination

enum MoreDestination: Hashable {
    case deviceHealth
    case batteryInsights
    case systemTips
    case dashboard
    case cleaningHistory
    case settings
}

// MARK: - Navigation View Modifier

struct NavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .photosCleaner:
                    PhotosOverviewView()
                case .videosCleaner:
                    Text("Videos Cleaner") // TODO: Implement
                case .contactsCleaner:
                    Text("Contacts Cleaner") // TODO: Implement
                case .secretFolder:
                    Text("Secret Folder") // TODO: Implement
                case .storageOverview:
                    Text("Storage Overview") // TODO: Implement
                case .battery:
                    BatteryInsightsView()
                }
            }
            .navigationDestination(for: PhotosDestination.self) { destination in
                switch destination {
                case .duplicates:
                    DuplicatesView()
                case .similar:
                    SimilarPhotosView()
                case .screenshots:
                    ScreenshotsView()
                case .livePhotos:
                    LivePhotosView()
                case .burst:
                    BurstPhotosView()
                case .bigFiles:
                    BigFilesView()
                case .swipeClean:
                    SwipeHubView()
                }
            }
            .navigationDestination(for: PhotoCategoryNav.self) { destination in
                switch destination {
                case .screenshots:
                    ScreenshotsView()
                case .similar:
                    SimilarPhotosView()
                case .videos:
                    VideosView()
                case .shortVideos:
                    ShortVideosView()
                case .livePhotos:
                    LivePhotosView()
                case .duplicates:
                    DuplicatesView()
                case .burst:
                    BurstPhotosView()
                case .bigFiles:
                    BigFilesView()
                case .highlights:
                    HighlightsView()
                }
            }
            .navigationDestination(for: PhotoCategory.self) { category in
                switch category {
                case .screenshots:
                    ScreenshotsView()
                case .similar:
                    SimilarPhotosView()
                case .duplicates:
                    DuplicatesView()
                case .livePhotos:
                    LivePhotosView()
                case .burst:
                    BurstPhotosView()
                case .bigFiles:
                    BigFilesView()
                case .highlights:
                    HighlightsView()
                }
            }
            .navigationDestination(for: MoreDestination.self) { destination in
                switch destination {
                case .deviceHealth:
                    DeviceHealthView()
                case .batteryInsights:
                    BatteryInsightsView()
                case .systemTips:
                    SystemTipsView()
                case .dashboard:
                    DashboardView()
                case .cleaningHistory:
                    CleaningHistoryView()
                case .settings:
                    SettingsView()
                }
            }
    }
}

extension View {
    func withNavigationDestinations() -> some View {
        modifier(NavigationDestinationModifier())
    }
}

