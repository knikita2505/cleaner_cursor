import SwiftUI

struct CleanupRewardSheet: View {
    @ObservedObject private var coordinator = CleanupAccessCoordinator.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {
                    coordinator.dismissRewardSheet()
                }

            VStack(alignment: .leading, spacing: AppSpacing.blockSpacing) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(coordinator.formattedSelectedSize)
                            .font(AppFonts.titleM)
                            .foregroundColor(AppColors.textPrimary)
                        Text("\(coordinator.selectedCount) selected")
                            .font(AppFonts.bodyM)
                            .foregroundColor(AppColors.textTertiary)
                    }

                    Spacer()

                    Button {
                        coordinator.dismissRewardSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text("Start Cleanup")
                    .font(AppFonts.subtitleL)
                    .foregroundColor(AppColors.textPrimary)

                Text("To delete \(coordinator.formattedSelectedSize), upgrade to Premium or watch an ad.")
                    .font(AppFonts.bodyM)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if coordinator.exceedsAdCap && !coordinator.sliceItems.isEmpty {
                    Text("One ad cleans up to 500 MB. Remaining files stay selected.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if coordinator.sliceItems.isEmpty {
                    Text("These files are larger than 500 MB. Subscribe to Premium to clean them.")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusWarning)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if coordinator.isDailyAdLimitReached {
                    Text("Daily free cleanup limit reached")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusWarning)
                }

                if let message = coordinator.adStatusMessage {
                    Text(message)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.statusWarning)
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "Upgrade to Premium") {
                        coordinator.reopenPaywallFromRewardSheet()
                    }

                    adButton
                }
            }
            .padding(AppSpacing.screenPaddingLarge)
            .background(AppColors.backgroundModal)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.modalRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.modalRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }

    private var adButton: some View {
        let isDisabled = !coordinator.canUseAds || coordinator.isShowingAd
        let title = coordinator.isShowingAd
            ? String(localized: "Loading ad...")
            : String(localized: "Delete \(coordinator.formattedSliceSize) with Ads")

        return Button {
            Task {
                await coordinator.watchAdAndClean()
            }
        } label: {
            HStack(spacing: AppSpacing.iconTextSpacing) {
                if coordinator.isShowingAd {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textSecondary))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(title)
                        .font(AppFonts.buttonSecondary)
                }
            }
            .foregroundColor(isDisabled ? AppColors.textTertiary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.buttonHeightSecondary)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                    .stroke(
                        isDisabled ? AppColors.borderSecondary.opacity(0.4) : AppColors.borderSecondary,
                        lineWidth: 1
                    )
            )
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
    }
}
