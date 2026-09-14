import Foundation

enum AdMobConfig {
    static let applicationID = "ca-app-pub-5315661113522929~3480780973"
    static let productionRewardedAdUnitID = "ca-app-pub-5315661113522929/5999684093"
    static let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    static let rewardedAdUnitID = productionRewardedAdUnitID
    static let adCleanupByteCap: Int64 = 500 * 1024 * 1024
    static let dailyAdCleanupLimit = 3
}
