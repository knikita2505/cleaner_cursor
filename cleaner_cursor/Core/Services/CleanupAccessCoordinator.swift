import Foundation
import SwiftUI

struct CleanupItem: Identifiable, Equatable {
    let id: String
    let byteSize: Int64
}

@MainActor
final class CleanupAccessCoordinator: ObservableObject {
    static let shared = CleanupAccessCoordinator()

    @Published var showRewardSheet = false
    @Published var isShowingAd = false
    @Published var adStatusMessage: String?

    private(set) var pendingItems: [CleanupItem] = []
    private var pendingPerform: (([String]) async -> Void)?
    private var didPurchaseDuringPaywall = false
    private var isAwaitingCleanupPaywall = false
    private var flowContinuation: CheckedContinuation<Void, Never>?

    private let dailyCountKey = "cleanup_ad_rewards_count"
    private let dailyDateKey = "cleanup_ad_rewards_date"

    private init() {}

    var selectedByteSize: Int64 {
        pendingItems.reduce(0) { $0 + $1.byteSize }
    }

    var selectedCount: Int {
        pendingItems.count
    }

    var formattedSelectedSize: String {
        Self.formatBytes(selectedByteSize)
    }

    var sliceItems: [CleanupItem] {
        Self.slice(pendingItems)
    }

    var sliceByteSize: Int64 {
        sliceItems.reduce(0) { $0 + $1.byteSize }
    }

    var formattedSliceSize: String {
        Self.formatBytes(sliceByteSize)
    }

    var exceedsAdCap: Bool {
        selectedByteSize > AdMobConfig.adCleanupByteCap
    }

    var canUseAds: Bool {
        !isDailyAdLimitReached && !sliceItems.isEmpty
    }

    var remainingAdCleanupsToday: Int {
        resetDailyCountIfNeeded()
        return max(0, AdMobConfig.dailyAdCleanupLimit - UserDefaults.standard.integer(forKey: dailyCountKey))
    }

    var isDailyAdLimitReached: Bool {
        remainingAdCleanupsToday == 0
    }

    func requestCleanup(items: [CleanupItem], perform: @escaping ([String]) async -> Void) async {
        guard !items.isEmpty else { return }

        if SubscriptionManager.shared.isPremium {
            await perform(items.map(\.id))
            return
        }

        pendingItems = items
        pendingPerform = perform
        didPurchaseDuringPaywall = false
        isAwaitingCleanupPaywall = true
        adStatusMessage = nil

        await withCheckedContinuation { continuation in
            flowContinuation = continuation
            SubscriptionManager.shared.showPaywall(for: .reachedLimits)
        }
    }

    func handlePurchaseSuccess() {
        guard isAwaitingCleanupPaywall || showRewardSheet else { return }
        didPurchaseDuringPaywall = true
        showRewardSheet = false
        isAwaitingCleanupPaywall = false

        let items = pendingItems
        let perform = pendingPerform
        clearPending()

        Task {
            await perform?(items.map(\.id))
            resumeFlow()
        }
    }

    func handlePaywallDismissed() {
        guard isAwaitingCleanupPaywall else { return }
        isAwaitingCleanupPaywall = false

        if didPurchaseDuringPaywall {
            didPurchaseDuringPaywall = false
            return
        }

        guard pendingPerform != nil else {
            resumeFlow()
            return
        }
        showRewardSheet = true
    }

    func reopenPaywallFromRewardSheet() {
        showRewardSheet = false
        didPurchaseDuringPaywall = false
        isAwaitingCleanupPaywall = true
        SubscriptionManager.shared.showPaywall(for: .reachedLimits)
    }

    func dismissRewardSheet() {
        showRewardSheet = false
        adStatusMessage = nil
        clearPending()
        resumeFlow()
    }

    func watchAdAndClean() async {
        guard canUseAds else { return }
        isShowingAd = true
        adStatusMessage = nil

        let result = await RewardedAdService.shared.show()
        isShowingAd = false

        switch result {
        case .rewarded:
            recordSuccessfulAdCleanup()
            let ids = sliceItems.map(\.id)
            let perform = pendingPerform
            showRewardSheet = false
            clearPending()
            // Let the ad and reward sheet finish dismissing so Photos can present its dialog.
            try? await Task.sleep(nanoseconds: 450_000_000)
            await perform?(ids)
            resumeFlow()
        case .notReady:
            adStatusMessage = String(localized: "Ad is not ready. Try again in a moment.")
            RewardedAdService.shared.preload()
        case .dismissed, .failed:
            adStatusMessage = String(localized: "Watch the full ad to clean files for free.")
        }
    }

    static func slice(_ items: [CleanupItem]) -> [CleanupItem] {
        var running: Int64 = 0
        var result: [CleanupItem] = []
        for item in items {
            guard item.byteSize <= AdMobConfig.adCleanupByteCap else { continue }
            guard running + item.byteSize <= AdMobConfig.adCleanupByteCap else { continue }
            result.append(item)
            running += item.byteSize
        }
        return result
    }

    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func recordSuccessfulAdCleanup() {
        resetDailyCountIfNeeded()
        let current = UserDefaults.standard.integer(forKey: dailyCountKey)
        UserDefaults.standard.set(current + 1, forKey: dailyCountKey)
    }

    private func resetDailyCountIfNeeded() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if UserDefaults.standard.string(forKey: dailyDateKey) != today {
            UserDefaults.standard.set(today, forKey: dailyDateKey)
            UserDefaults.standard.set(0, forKey: dailyCountKey)
        }
    }

    private func clearPending() {
        pendingItems = []
        pendingPerform = nil
    }

    private func resumeFlow() {
        flowContinuation?.resume()
        flowContinuation = nil
    }
}
