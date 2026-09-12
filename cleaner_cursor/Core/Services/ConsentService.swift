import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

@MainActor
final class ConsentService {
    static let shared = ConsentService()

    private var didStartMobileAds = false
    private var isPreparing = false

    private init() {}

    func prepareAdsAfterTrackingDecision() async {
        guard ATTrackingManager.trackingAuthorizationStatus != .notDetermined else { return }
        await prepareAdsIfNeeded()
    }

    func prepareAdsIfNeeded() async {
        guard !SubscriptionManager.shared.isPremium else { return }
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        do {
            let parameters = RequestParameters()
            parameters.isTaggedForUnderAgeOfConsent = false
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            if let viewController = UIViewController.topMost {
                try await ConsentForm.loadAndPresentIfRequired(from: viewController)
            }
        } catch {
            print("UMP consent error: \(error.localizedDescription)")
        }

        startMobileAdsIfAllowed()
    }

    func startMobileAdsIfAllowed() {
        guard ConsentInformation.shared.canRequestAds else { return }
        guard !didStartMobileAds else {
            RewardedAdService.shared.preload()
            return
        }
        didStartMobileAds = true
        MobileAds.shared.start()
        RewardedAdService.shared.preload()
    }
}
