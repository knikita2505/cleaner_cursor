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
                    VStack(spacing: 18) {
                        headerSection
                        storageSection
                        plansSection
                        trustLine
                        ctaButton
                        footerLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                    .padding(.top, 6)
                }
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.20))
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("CLEAN UP YOUR")
                .font(.system(size: 40, weight: .black))
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
        .padding(.bottom, 6)
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
                        .animation(.easeInOut(duration: 2.5), value: vm.storageProgress)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 10)

            HStack(spacing: 6) {
                Text("\(Int(vm.storageProgress * 100))")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(progressColor)

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
            isDimmed: !vm.weeklyAvailable,
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
            isDimmed: !vm.yearlyAvailable,
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
        .disabled(vm.isPurchasing || !vm.hasAnyProduct)
        .opacity(vm.isPurchasing ? 0.85 : 1.0)
        .padding(.top, 4)
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
        .padding(.top, 8)
    }
}

// MARK: - ViewModel

@MainActor
final class PaywallViewModel: ObservableObject {

    // UI state
    @Published var freeTrialEnabled: Bool = true
    @Published var selectedPlan: PaywallSubscriptionPlan = .weekly

    @Published var storageProgress: CGFloat = 0.82
    @Published var photosCount: Int = 823
    @Published var icloudCount: Int = 470

    @Published var isPurchasing: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?

    // Apphud products
    private(set) var weeklyProduct: ApphudProduct?
    private(set) var yearlyProduct: ApphudProduct?
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
        guard let p = weeklyProduct?.skProduct else { return "Loading…" }
        let price = formatPrice(p)
        return "then \(price) / week"
    }

    var yearlyMainLine: String {
        guard let p = yearlyProduct?.skProduct else { return "Loading…" }
        return "\(formatPrice(p)) / year"
    }

    var yearlyPerWeekLine: String {
        guard let p = yearlyProduct?.skProduct else { return "" }
        let weekly = (p.price as Decimal) / 52
        return "\(formatPrice(weekly, locale: p.priceLocale))/WEEK"
    }

    func onAppear() {
        // Load products and log paywall shown
        loadProducts()

        // Run intro animation
        runIntroAnimation()
    }

    func onTrialToggleChanged(_ enabled: Bool) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if enabled {
                selectedPlan = .weekly
            } else {
                selectedPlan = .yearly
            }
        }
    }

    func select(_ plan: PaywallSubscriptionPlan) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedPlan = plan
            if plan == .yearly { freeTrialEnabled = false }
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
        withAnimation(.easeInOut(duration: 2.5)) {
            storageProgress = 0.25
        }
        animateCounter(from: 823, to: 205) { self.photosCount = $0 }
        animateCounter(from: 470, to: 117) { self.icloudCount = $0 }
    }

    private func animateCounter(from start: Int, to end: Int, update: @escaping (Int) -> Void) {
        let duration: Double = 2.5
        let steps = 60
        let stepDuration = duration / Double(steps)
        let diff = start - end

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                let t = Double(step) / Double(steps)
                let eased = self.easeInOut(t)
                let current = start - Int(Double(diff) * eased)
                update(current)
            }
        }
    }

    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
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

            // Sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
                .offset(x: -150, y: -120)

            Image(systemName: "sparkle")
                .font(.system(size: 18))
                .foregroundStyle(Color.white.opacity(0.75))
                .offset(x: 150, y: -150)

            Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.45))
                .offset(x: 150, y: -60)
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
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.20))
                    .frame(width: 78, height: 78)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .overlay(
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(titleTop)
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.white.opacity(0.65))

                    Text(mainPriceLine)
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
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
