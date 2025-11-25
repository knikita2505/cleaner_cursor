import SwiftUI
import StoreKit

// MARK: - Paywall View
/// Экран подписки

struct PaywallView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: SubscriptionService.ProductID = .yearly
    @State private var isPurchasing: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            AuroraBackground(animated: false)
            
            VStack(spacing: 0) {
                // Close Button
                HStack {
                    Spacer()
                    
                    IconButton(icon: "xmark", size: 18, color: AppColors.textTertiary) {
                        dismiss()
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Features
                        featuresSection
                        
                        // Plans
                        plansSection
                        
                        // CTA
                        ctaSection
                        
                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700"),
                                Color(hex: "FFA500")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 20, x: 0, y: 8)
            
            // Title
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(AppFonts.titleL)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Get unlimited access to all features")
                    .font(AppFonts.bodyL)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "infinity", text: "Unlimited cleaning")
            featureRow(icon: "photo.stack.fill", text: "All photo categories")
            featureRow(icon: "video.fill", text: "Video compression")
            featureRow(icon: "lock.fill", text: "Secret folder")
            featureRow(icon: "bell.fill", text: "Smart notifications")
            featureRow(icon: "xmark.circle.fill", text: "No ads")
        }
        .padding(AppSpacing.containerPadding)
        .background(AppColors.backgroundSecondary.opacity(0.6))
        .cornerRadius(AppSpacing.cardRadius)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 24)
            
            Text(text)
                .font(AppFonts.bodyL)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.statusSuccess)
        }
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(spacing: 12) {
            // Yearly Plan
            planCard(
                id: .yearly,
                title: "Yearly",
                price: subscriptionService.yearlyProduct?.displayPrice ?? "$34.99",
                period: "/year",
                badge: "Best Value",
                savings: "Save 70%",
                isSelected: selectedPlan == .yearly
            )
            
            // Weekly Plan
            planCard(
                id: .weekly,
                title: "Weekly",
                price: subscriptionService.weeklyProduct?.displayPrice ?? "$6.99",
                period: "/week",
                badge: nil,
                savings: nil,
                isSelected: selectedPlan == .weekly
            )
            
            // Lifetime (if variant B)
            if appState.paywallVariant == .b {
                planCard(
                    id: .lifetime,
                    title: "Lifetime",
                    price: subscriptionService.lifetimeProduct?.displayPrice ?? "$29.99",
                    period: "one-time",
                    badge: "Limited Offer",
                    savings: nil,
                    isSelected: selectedPlan == .lifetime
                )
            }
        }
    }
    
    private func planCard(
        id: SubscriptionService.ProductID,
        title: String,
        price: String,
        period: String,
        badge: String?,
        savings: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedPlan = id
            }
        } label: {
            HStack {
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.accentBlue : AppColors.borderSecondary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.accentBlue)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(AppFonts.subtitleL)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    badge == "Best Value" ? AppColors.statusSuccess : AppColors.statusWarning
                                )
                                .cornerRadius(6)
                        }
                    }
                    
                    if let savings = savings {
                        Text(savings)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.statusSuccess)
                    }
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(AppFonts.titleM)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(period)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.containerPadding)
            .background(
                isSelected
                    ? AppColors.accentBlue.opacity(0.15)
                    : AppColors.backgroundSecondary.opacity(0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonRadius)
                    .stroke(
                        isSelected ? AppColors.accentBlue : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(AppSpacing.buttonRadius)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: "Start Free Trial",
                isLoading: isPurchasing
            ) {
                Task {
                    await purchase()
                }
            }
            
            Text("3 days free, then \(selectedPlanPrice)")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    private var selectedPlanPrice: String {
        switch selectedPlan {
        case .weekly:
            return subscriptionService.weeklyProduct?.displayPrice ?? "$6.99/week"
        case .yearly:
            return subscriptionService.yearlyProduct?.displayPrice ?? "$34.99/year"
        case .lifetime:
            return subscriptionService.lifetimeProduct?.displayPrice ?? "$29.99"
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restore Purchases
            GhostButton(title: "Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            
            // Terms & Privacy
            HStack(spacing: 16) {
                Button("Terms of Use") {
                    // Open terms
                }
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary.opacity(0.6))
                
                Text("•")
                    .foregroundColor(AppColors.textTertiary.opacity(0.4))
                
                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary.opacity(0.6))
            }
        }
    }
    
    // MARK: - Purchase
    
    private func purchase() async {
        guard let product = subscriptionService.product(for: selectedPlan) else { return }
        
        isPurchasing = true
        
        do {
            let success = try await subscriptionService.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        
        isPurchasing = false
    }
}

// MARK: - Preview

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(AppState.shared)
    }
}

