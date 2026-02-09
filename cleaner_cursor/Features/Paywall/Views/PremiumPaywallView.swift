import SwiftUI
import ApphudSDK
import StoreKit

// MARK: - PremiumPaywallView
// Used for premium_feature and reached_limits placements

struct PremiumPaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: PaywallViewModel
    
    let placement: PaywallPlacement
    var onPurchaseSuccess: (() -> Void)?
    
    init(placement: PaywallPlacement = .premiumFeature, onPurchaseSuccess: (() -> Void)? = nil) {
        self.placement = placement
        self.onPurchaseSuccess = onPurchaseSuccess
        self._vm = StateObject(wrappedValue: PaywallViewModel(placement: placement))
    }

    var body: some View {
        ZStack {
            PremiumPaywallBackground()

            VStack(spacing: 0) {
                topBar

                // All content - single page, no scroll
                VStack(spacing: 12) {
                    headerSection
                    storageSection
                    featuresSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 2)
                
                Spacer()
                
                // Bottom content - fixed at bottom
                VStack(spacing: 10) {
                    plansSection
                    trustLine
                    ctaButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
                
                // Footer
                footerLinks
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.purchaseSuccessful) { _, success in
            if success {
                SubscriptionManager.shared.handleSuccessfulPurchase()
                onPurchaseSuccess?()
                dismiss()
            }
        }
        .alert("Purchase failed", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Something went wrong.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.30))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Text("UNLOCK")
                .font(.system(size: 30, weight: .black))
                .fontDesign(.rounded)
                .tracking(1.0)
                .foregroundStyle(.white)

            PremiumPillTitle(text: "PREMIUM")
        }
        .padding(.top, 2)
    }

    // MARK: - Storage

    private var storageSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 44) {
                PremiumAppIconBadgeAsset(
                    assetName: "pw_photos",
                    title: "Photos",
                    count: vm.photosCount
                )

                PremiumAppIconBadgeAsset(
                    assetName: "pw_icloud",
                    title: "iCloud",
                    count: vm.icloudCount
                )
            }

            progressBar
        }
        .padding(.top, 0)
        .padding(.bottom, 8)
    }

    private var progressBar: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(height: 12)

                    Capsule()
                        .fill(progressGradient)
                        .frame(width: geo.size.width * vm.storageProgress, height: 12)
                        .animation(.linear(duration: 0.15), value: vm.storageProgress)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 10)

            HStack(spacing: 6) {
                Text("\(vm.percentageDisplay)")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(progressColor)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: vm.percentageDisplay)

                Text("from 100% used")
                    .font(.system(size: 18, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var progressGradient: LinearGradient {
        if vm.storageProgress > 0.6 {
            return LinearGradient(colors: [Color(hex: "FF5252"), Color(hex: "FF8A65")], startPoint: .leading, endPoint: .trailing)
        } else if vm.storageProgress > 0.4 {
            return LinearGradient(colors: [Color(hex: "FFB74D"), Color(hex: "FFC107")], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color(hex: "66BB6A"), Color(hex: "4CAF50")], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var progressColor: Color {
        if vm.storageProgress > 0.6 {
            return Color(hex: "FF5252")
        } else if vm.storageProgress > 0.4 {
            return Color(hex: "FFB74D")
        } else {
            return Color(hex: "66BB6A")
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 8) {
            FeatureRow(icon: "infinity", text: "Ad-Free Unlimited Cleanup")
            FeatureRow(icon: "lock.shield.fill", text: "Private Storage Vault")
            FeatureRow(icon: "person.2.fill", text: "Smart Contact Organizer")
            FeatureRow(icon: "chart.bar.fill", text: "Cleanup Analytics")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 12) {
            // Show loading state
            if vm.isLoadingProducts {
                loadingPlansView
            }
            // Show critical error (no products at all)
            else if let error = vm.loadingError, !vm.hasAnyProduct {
                errorPlansView(error: error)
            }
            // Show normal plans
            else {
                planCardWeekly
                planCardYearly
            }
        }
    }
    
    private var loadingPlansView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading subscription options...")
                .font(.system(size: 14, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.60))
        }
        .frame(height: 150)
    }
    
    private func errorPlansView(error: PaywallError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "FFB74D"))
            
            VStack(spacing: 6) {
                Text(error.title)
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                
                Text(error.message)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.white.opacity(0.60))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                vm.retryLoadProducts()
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(hex: "8B5CF6").opacity(0.80))
                    )
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 20)
    }

    private var planCardWeekly: some View {
        PremiumPlanCard(
            titleTop: vm.weeklyTitleTop,
            mainPriceLine: vm.weeklyMainLine,
            rightBadgeText: vm.weeklyBadge,
            rightSubBadgeText: nil,
            isSelected: vm.selectedPlan == .weekly,
            isDimmed: false,
            onTap: { vm.select(.weekly) }
        )
    }

    private var planCardYearly: some View {
        PremiumPlanCard(
            titleTop: "YEARLY ACCESS",
            mainPriceLine: vm.yearlyMainLine,
            rightBadgeText: "BEST OFFER",
            rightSubBadgeText: vm.yearlyPerWeekLine,
            isSelected: vm.selectedPlan == .yearly,
            isDimmed: false,
            onTap: { vm.select(.yearly) }
        )
    }
    
    // MARK: - Prices Note
    
    @ViewBuilder
    private var pricesNote: some View {
        if vm.pricesMissing {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                
                Text("Prices will be displayed at checkout")
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.rounded)
            }
            .foregroundStyle(Color.white.opacity(0.50))
            .padding(.top, 4)
        }
    }

    // MARK: - Trust line

    private var trustLine: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))

                Text(vm.isTrialEligible ? "NO PAYMENT NOW" : "CANCEL ANYTIME")
                    .font(.system(size: 13, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            
            pricesNote
        }
        .padding(.top, 4)
    }

    // MARK: - CTA
    
    private var isButtonDisabled: Bool {
        vm.isPurchasing || vm.isLoadingProducts || !vm.hasAnyProduct
    }

    private var ctaButton: some View {
        Button {
            vm.purchaseSelected()
        } label: {
            ZStack {
                if vm.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if vm.isLoadingProducts {
                    Text("LOADING...")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white.opacity(0.70))
                } else {
                    Text(vm.isTrialEligible && vm.selectedPlan == .weekly ? "START FREE TRIAL" : "CONTINUE")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 22, x: 0, y: 12)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.65 : 1.0)
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 22) {
            Button("Restore") {
                vm.restore()
            }
            .font(.system(size: 13, weight: .medium))
            .fontDesign(.rounded)
            .foregroundStyle(Color.white.opacity(0.40))

            Link("Terms of use", destination: URL(string: PremiumPaywallConstants.termsURL)!)
                .font(.system(size: 13, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.40))

            Link("Privacy Policy", destination: URL(string: PremiumPaywallConstants.privacyURL)!)
                .font(.system(size: 13, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .padding(.top, 12)
    }
}

// MARK: - Constants

private enum PremiumPaywallConstants {
    static let termsURL = "https://magicswipe.app/terms.html"
    static let privacyURL = "https://magicswipe.app/privacy.html"
}

// MARK: - UI Components

private struct PremiumPaywallBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1A0A2E"),
                    Color(hex: "16082A"),
                    Color(hex: "0D0618")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Glow blobs
            Circle()
                .fill(Color(hex: "8B5CF6").opacity(0.30))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 130, y: -220)

            Circle()
                .fill(Color(hex: "A78BFA").opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -150, y: 260)

            // Sparkles - purple color
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.85))
                .offset(x: -140, y: -390)
            
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.70))
                .offset(x: -155, y: -280)
            
            Image(systemName: "sparkle")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.95))
                .offset(x: 160, y: -320)
            
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.80))
                .offset(x: 155, y: -250)
            
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.60))
                .offset(x: 165, y: -200)
        }
    }
}

private struct PremiumPillTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .black))
            .fontDesign(.rounded)
            .tracking(1.0)
            .foregroundStyle(Color(hex: "1A0A2E"))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "A78BFA").opacity(0.92))
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 14, x: 0, y: 8)
            )
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "A78BFA"))
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(.white.opacity(0.90))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "66BB6A"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct PremiumAppIconBadgeAsset: View {
    let assetName: String
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.20))
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .overlay(
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                    )

                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FF4D4D")))
                    .offset(x: 10, y: -10)
                    .contentTransition(.numericText())
            }

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.80))
        }
    }
}

private struct PremiumGlassCard: View {
    var corner: CGFloat = 18
    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

private struct PremiumPlanCard: View {
    let titleTop: String
    let mainPriceLine: String?
    let rightBadgeText: String
    let rightSubBadgeText: String?
    let isSelected: Bool
    let isDimmed: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            if !isDimmed { onTap() }
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleTop)
                        .font(.system(size: 15, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.white.opacity(0.70))

                    if let priceLine = mainPriceLine {
                        Text(priceLine)
                            .font(.system(size: 14, weight: .medium))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.opacity(0.90))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(rightBadgeText)
                        .font(.system(size: 11, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(isSelected ? .white : Color(hex: "A78BFA"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(
                                isSelected
                                ? Color(hex: "8B5CF6").opacity(0.95)
                                : Color(hex: "8B5CF6").opacity(0.28)
                            )
                        )

                    if let rightSubBadgeText {
                        Text(rightSubBadgeText)
                            .font(.system(size: 11, weight: .semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    PremiumGlassCard(corner: 18)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "8B5CF6").opacity(0.18))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color(hex: "8B5CF6").opacity(0.95) : Color.clear, lineWidth: 2)
            )
            .opacity(isDimmed ? 0.45 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct PremiumPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPaywallView()
            .preferredColorScheme(.dark)
    }
}
