import Foundation
import GoogleMobileAds
import UIKit

enum RewardedShowResult {
    case rewarded
    case dismissed
    case failed
    case notReady
}

@MainActor
final class RewardedAdService: NSObject {
    static let shared = RewardedAdService()

    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var presenter: RewardedAdPresenter?

    private override init() {
        super.init()
    }

    func preload() {
        guard !SubscriptionManager.shared.isPremium else { return }
        guard rewardedAd == nil, !isLoading else { return }
        isLoading = true

        RewardedAd.load(with: AdMobConfig.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    print("Rewarded ad failed to load: \(error.localizedDescription)")
                    self.rewardedAd = nil
                    return
                }
                self.rewardedAd = ad
            }
        }
    }

    func show() async -> RewardedShowResult {
        guard let ad = rewardedAd else {
            preload()
            return .notReady
        }
        guard let viewController = UIViewController.topMost else {
            return .failed
        }

        rewardedAd = nil
        let presenter = RewardedAdPresenter()
        self.presenter = presenter
        ad.fullScreenContentDelegate = presenter

        return await withCheckedContinuation { continuation in
            presenter.finish = { [weak self] result in
                Task { @MainActor in
                    self?.presenter = nil
                    self?.preload()
                    continuation.resume(returning: result)
                }
            }

            ad.present(from: viewController) {
                presenter.didEarnReward = true
            }
        }
    }
}

private final class RewardedAdPresenter: NSObject, FullScreenContentDelegate {
    var didEarnReward = false
    var finish: ((RewardedShowResult) -> Void)?
    private var didFinish = false

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        complete(.failed)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        complete(didEarnReward ? .rewarded : .dismissed)
    }

    private func complete(_ result: RewardedShowResult) {
        guard !didFinish else { return }
        didFinish = true
        finish?(result)
    }
}

extension UIViewController {
    static var topMost: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        guard let root = window?.rootViewController else { return nil }
        return topMost(from: root)
    }

    private static func topMost(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return topMost(from: presented)
        }
        if let navigation = controller as? UINavigationController, let visible = navigation.visibleViewController {
            return topMost(from: visible)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(from: selected)
        }
        return controller
    }
}
