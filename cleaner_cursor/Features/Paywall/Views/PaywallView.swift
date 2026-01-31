import SwiftUI
import ApphudSDK
import StoreKit

// MARK: - PaywallView (Native, iOS 17, Apphud-powered)

struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PaywallViewModel()

    var body: some View {
        ZStack {
            PaywallBackground()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerSection
                        storageSection
                        plansSection
                        trustLine
                        ctaButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                }
                
                // Footer always at bottom
                footerLinks
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            vm.onAppear()
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
        VStack(spacing: 10) {
            Text("CLEAN UP YOUR")
                .font(.system(size: 38, weight: .black))
                .fontDesign(.rounded)
                .tracking(1.2)
                .foregroundStyle(.white)

            PillTitle(text: "STORAGE")
        }
        .padding(.top, 4)
    }

    // MARK: - Storage

    private var storageSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 44) {
                AppIconBadgeAsset(
                    assetName: "pw_photos",
                    title: "Photos",
                    count: vm.photosCount
                )

                AppIconBadgeAsset(
                    assetName: "pw_icloud",
                    title: "iCloud",
                    count: vm.icloudCount
                )
            }

            progressBar
        }
        .padding(.top, 2)
        .padding(.bottom, 24)
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

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 12) {
            freeTrialToggle

            planCardWeekly

            planCardYearly
        }
    }

    private var freeTrialToggle: some View {
        HStack {
            Text("Free Trial Enabled")
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.white)

            Spacer()

            Toggle("", isOn: $vm.freeTrialEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "4CAF50")))
                .onChange(of: vm.freeTrialEnabled) { _, newValue in
                    vm.onTrialToggleChanged(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(GlassCard(corner: 18))
    }

    private var planCardWeekly: some View {
        PlanCard(
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
        PlanCard(
            titleTop: "YEARLY ACCESS",
            mainPriceLine: vm.yearlyMainLine,
            rightBadgeText: "BEST OFFER",
            rightSubBadgeText: vm.yearlyPerWeekLine,
            isSelected: vm.selectedPlan == .yearly,
            isDimmed: false,
            onTap: { vm.select(.yearly) }
        )
    }

    // MARK: - Trust line

    private var trustLine: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))

            Text(vm.freeTrialEnabled ? "NO PAYMENT NOW" : "CANCEL ANYTIME")
                .font(.system(size: 13, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(.top, 4)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            vm.purchaseSelected()
        } label: {
            ZStack {
                if vm.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(vm.freeTrialEnabled ? "CONTINUE FOR FREE" : "CONTINUE")
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
        .disabled(vm.isPurchasing)
        .opacity(vm.isPurchasing ? 0.85 : 1.0)
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

            Link("Terms of use", destination: URL(string: PaywallConstants.termsURL)!)
                .font(.system(size: 13, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.40))

            Link("Privacy Policy", destination: URL(string: PaywallConstants.privacyURL)!)
                .font(.system(size: 13, weight: .medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .padding(.top, 12)
    }
}

// MARK: - ViewModel

@MainActor
final class PaywallViewModel: ObservableObject {

    // UI state
    @Published var freeTrialEnabled: Bool = true
    @Published var selectedPlan: PaywallSubscriptionPlan = .weekly

    @Published var storageProgress: CGFloat = 1.0
    @Published var percentageDisplay: Int = 100
    @Published var photosCount: Int = 823
    @Published var icloudCount: Int = 470

    @Published var isPurchasing: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // Animation timers
    private var percentTimer: Timer?
    private var photosTimer: Timer?
    private var icloudTimer: Timer?
    private var cycleTimer: Timer?

    // Apphud products
    @Published private(set) var weeklyProduct: ApphudProduct?
    @Published private(set) var yearlyProduct: ApphudProduct?
    private var currentPaywall: ApphudPaywall?

    var weeklyAvailable: Bool { weeklyProduct != nil }
    var yearlyAvailable: Bool { yearlyProduct != nil }
    var hasAnyProduct: Bool { weeklyAvailable || yearlyAvailable }

    // Display strings
    var weeklyTitleTop: String {
        "3-DAY FREE TRIAL"
    }

    var weeklyBadge: String { "3 DAYS FREE" }

    var weeklyMainLine: String {
        guard let p = weeklyProduct?.skProduct else { return "then €5.19 / week" }
        let price = formatPrice(p)
        return "then \(price) / week"
    }

    var yearlyMainLine: String {
        guard let p = yearlyProduct?.skProduct else { return "€25.99 / year" }
        return "\(formatPrice(p)) / year"
    }

    var yearlyPerWeekLine: String {
        guard let p = yearlyProduct?.skProduct else { return "€0.50/WEEK" }
        let weekly = (p.price as Decimal) / 52
        return "\(formatPrice(weekly, locale: p.priceLocale))/WEEK"
    }

    func onAppear() {
        // Load products
        loadProducts()

        // Run intro animation after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.runIntroAnimation()
        }
    }

    func onTrialToggleChanged(_ enabled: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if enabled {
                selectedPlan = .weekly
            } else {
                selectedPlan = .yearly
            }
        }
    }

    func select(_ plan: PaywallSubscriptionPlan) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPlan = plan
            // Sync toggle with plan selection
            if plan == .weekly {
                freeTrialEnabled = true
            } else {
                freeTrialEnabled = false
            }
        }
    }

    func purchaseSelected() {
        let product: ApphudProduct?
        switch selectedPlan {
        case .weekly:
            product = weeklyProduct
        case .yearly:
            product = yearlyProduct
        }

        guard let product else {
            showErr("Product not available yet.")
            return
        }

        isPurchasing = true

        Apphud.purchase(product) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPurchasing = false

                if result.success {
                    // Purchase successful - can dismiss or show success UI
                } else {
                    self.showErr(result.error?.localizedDescription ?? "Purchase failed.")
                }
            }
        }
    }

    func restore() {
        isPurchasing = true
        Apphud.restorePurchases { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPurchasing = false
                if !result.success, let error = result.error {
                    self.showErr(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Private

    private func loadProducts() {
        Apphud.fetchPlacements { [weak self] placements, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                // Find placement by identifier
                guard let placement = placements.first(where: { $0.identifier == PaywallConstants.placementId }),
                      let paywall = placement.paywall else {
                    return
                }
                
                self.currentPaywall = paywall
                
                // Log paywall shown
                Apphud.paywallShown(paywall)
                
                // Get products from paywall
                let products = paywall.products
                
                self.weeklyProduct = products.first(where: { $0.productId == PaywallConstants.weeklyProductId })
                self.yearlyProduct = products.first(where: { $0.productId == PaywallConstants.yearlyProductId })

                // If weekly not available but trial enabled, switch to yearly
                if self.freeTrialEnabled, self.weeklyProduct == nil, self.yearlyProduct != nil {
                    self.freeTrialEnabled = false
                    self.selectedPlan = .yearly
                }
                if self.yearlyProduct == nil, self.weeklyProduct != nil {
                    self.selectedPlan = .weekly
                }
            }
        }
    }

    private func runIntroAnimation() {
        runAnimationCycle()
    }
    
    private func stopAllTimers() {
        percentTimer?.invalidate()
        photosTimer?.invalidate()
        icloudTimer?.invalidate()
        cycleTimer?.invalidate()
        percentTimer = nil
        photosTimer = nil
        icloudTimer = nil
        cycleTimer = nil
    }
    
    private func runAnimationCycle() {
        stopAllTimers()
        
        let duration: Double = 10.0
        let pauseBeforeRestart: Double = 2.0
        
        // Reset to initial values
        percentageDisplay = 100
        storageProgress = 1.0
        photosCount = 823
        icloudCount = 470
        
        // Each counter decreases by 1, but at different speeds to finish at the same time
        // Percent: 100 → 25 = 75 steps, interval = 10/75 = 0.133 sec
        // Photos: 823 → 205 = 618 steps, interval = 10/618 = 0.016 sec
        // iCloud: 470 → 117 = 353 steps, interval = 10/353 = 0.028 sec
        
        let percentSteps = 100 - 25 // 75
        let photosSteps = 823 - 205 // 618
        let icloudSteps = 470 - 117 // 353
        
        let percentInterval = duration / Double(percentSteps)
        let photosInterval = duration / Double(photosSteps)
        let icloudInterval = duration / Double(icloudSteps)
        
        // Percent timer
        percentTimer = Timer.scheduledTimer(withTimeInterval: percentInterval, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self else { timer.invalidate(); return }
                if self.percentageDisplay > 25 {
                    self.percentageDisplay -= 1
                    self.storageProgress = CGFloat(self.percentageDisplay) / 100.0
                } else {
                    timer.invalidate()
                }
            }
        }
        
        // Photos timer
        photosTimer = Timer.scheduledTimer(withTimeInterval: photosInterval, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self else { timer.invalidate(); return }
                if self.photosCount > 205 {
                    self.photosCount -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
        
        // iCloud timer
        icloudTimer = Timer.scheduledTimer(withTimeInterval: icloudInterval, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self else { timer.invalidate(); return }
                if self.icloudCount > 117 {
                    self.icloudCount -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
        
        // Schedule next cycle
        cycleTimer = Timer.scheduledTimer(withTimeInterval: duration + pauseBeforeRestart, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.runAnimationCycle()
            }
        }
    }

    private func showErr(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func formatPrice(_ product: SKProduct) -> String {
        formatPrice(product.price as Decimal, locale: product.priceLocale)
    }

    private func formatPrice(_ value: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

// MARK: - Constants

private enum PaywallConstants {
    // Apphud Placement ID (create placement in Apphud Dashboard)
    static let placementId = "onboarding"

    // App Store product IDs (must match App Store Connect + Apphud Products)
    static let weeklyProductId = "magicswipe.premium.week1"
    static let yearlyProductId = "magicswipe.premium.year1"

    // Footer links
    static let termsURL = "https://magicswipe.app/terms.html"
    static let privacyURL = "https://magicswipe.app/privacy.html"
}

// MARK: - Subscription Plan

enum PaywallSubscriptionPlan: String {
    case weekly, yearly
}

// MARK: - UI Components

private struct PaywallBackground: View {
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

            // Sparkles - purple color matching STORAGE block
            // Near close button (top left)
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.85))
                .offset(x: -140, y: -390)
            
            // Left side of header
            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.70))
                .offset(x: -155, y: -280)
            
            // Top right of header  
            Image(systemName: "sparkle")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.95))
                .offset(x: 160, y: -320)
            
            // Right side near STORAGE
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.80))
                .offset(x: 155, y: -250)
            
            // Small one on right
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "A78BFA").opacity(0.60))
                .offset(x: 165, y: -200)
        }
    }
}

private struct GlassCard: View {
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

private struct PillTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .black))
            .fontDesign(.rounded)
            .tracking(1.0)
            .foregroundStyle(Color(hex: "1A0A2E"))
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "A78BFA").opacity(0.92))
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 18, x: 0, y: 10)
            )
    }
}

private struct AppIconBadgeAsset: View {
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

private struct PlanCard: View {
    let titleTop: String
    let mainPriceLine: String
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

                    Text(mainPriceLine)
                        .font(.system(size: 14, weight: .medium))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
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
                    GlassCard(corner: 18)
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

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .preferredColorScheme(.dark)
    }
}
