import SwiftUI
import StoreKit

// MARK: - Paywall View
/// Экран подписки с анимированной визуализацией

struct PaywallView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var isPurchasing: Bool = false
    @State private var freeTrialEnabled: Bool = true
    
    // Animation states
    @State private var photosCount: Int = 678
    @State private var emailsCount: Int = 326
    @State private var progressPercent: Int = 100
    @State private var animationStarted: Bool = false
    
    // Target values
    private let targetPhotos = 169
    private let targetEmails = 81
    private let targetPercent = 25
    
    // Prices
    private let weeklyPrice = "$6.99"
    private let yearlyPrice = "$34.99"
    
    enum SubscriptionPlan {
        case weekly
        case yearly
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            // Sparkles
            sparklesOverlay
            
            VStack(spacing: 0) {
                // Close button
                closeButton
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Storage visualization
                        storageSection
                        
                        // Progress bar
                        progressSection
                        
                        // Free trial toggle
                        freeTrialToggle
                        
                        // Plans
                        plansSection
                        
                        // No payment text
                        noPaymentText
                        
                        // CTA Button
                        ctaButton
                        
                        // Footer links
                        footerLinks
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "1a0a2e"),
                Color(hex: "16213e"),
                Color(hex: "0f0f23")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Sparkles
    
    private var sparklesOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Top sparkles
                sparkle(size: 16)
                    .position(x: geometry.size.width * 0.15, y: 80)
                
                sparkle(size: 12)
                    .position(x: geometry.size.width * 0.35, y: 60)
                
                sparkle(size: 14)
                    .position(x: geometry.size.width * 0.65, y: 55)
                
                sparkle(size: 18)
                    .position(x: geometry.size.width * 0.85, y: 75)
                
                // Side sparkles
                sparkle(size: 10)
                    .position(x: geometry.size.width * 0.08, y: 200)
                
                sparkle(size: 12)
                    .position(x: geometry.size.width * 0.92, y: 180)
            }
        }
    }
    
    private func sparkle(size: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .light))
            .foregroundColor(Color(hex: "b794f6").opacity(0.7))
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .frame(width: 30, height: 30)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("CLEAN UP YOUR")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Storage badge
            Text("STORAGE")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "7c3aed").opacity(0.6))
                )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        HStack(spacing: 40) {
            // Photos
            storageItem(
                iconName: "photo.fill.on.rectangle.fill",
                iconColors: [Color(hex: "ff6b6b"), Color(hex: "feca57"), Color(hex: "48dbfb"), Color(hex: "ff9ff3")],
                count: photosCount,
                label: "Photos"
            )
            
            // ICloud
            storageItem(
                iconName: "icloud.fill",
                iconColors: [Color(hex: "74b9ff")],
                count: emailsCount,
                label: "ICloud"
            )
        }
        .padding(.top, 16)
    }
    
    private func storageItem(iconName: String, iconColors: [Color], count: Int, label: String) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Icon background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "2d2d44").opacity(0.8))
                    .frame(width: 90, height: 90)
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        iconColors.count > 1
                            ? AnyShapeStyle(LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(iconColors[0])
                    )
                    .frame(width: 90, height: 90)
                
                // Count badge
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "ff6b6b"))
                    .clipShape(Capsule())
                    .offset(x: 10, y: -10)
            }
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "3d3d5c"))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "ff6b6b"), Color(hex: "feca57")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progressPercent) / 100, height: 12)
                        .animation(.easeInOut(duration: 2.5), value: progressPercent)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 20)
            
            // Percentage text
            HStack(spacing: 4) {
                Text("\(progressPercent)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "ff6b6b"))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 2.5), value: progressPercent)
                
                Text("from 100% used")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Free Trial Toggle
    
    private var freeTrialToggle: some View {
        HStack {
            Text("Free Trial Enabled")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $freeTrialEnabled)
                .tint(Color(hex: "34d399"))
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2d2d44").opacity(0.6))
        )
        .padding(.top, 20)
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(spacing: 12) {
            // Weekly plan
            weeklyPlanCard
            
            // Yearly plan
            yearlyPlanCard
        }
    }
    
    private var weeklyPlanCard: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedPlan = .weekly
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("3-DAY FREE TRIAL")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "a78bfa"))
                    
                    Text("then \(weeklyPrice) / week")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("3 DAYS FREE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "f97316"), Color(hex: "ea580c")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        selectedPlan == .weekly
                            ? Color(hex: "7c3aed").opacity(0.3)
                            : Color(hex: "2d2d44").opacity(0.6)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedPlan == .weekly
                            ? Color(hex: "a78bfa")
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var yearlyPlanCard: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedPlan = .yearly
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YEARLY ACCESS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "a78bfa"))
                    
                    Text("\(yearlyPrice) / year")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BEST OFFER")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "a78bfa"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "a78bfa"), lineWidth: 1)
                        )
                    
                    Text("$0.67/WEEK")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        selectedPlan == .yearly
                            ? Color(hex: "7c3aed").opacity(0.3)
                            : Color(hex: "2d2d44").opacity(0.6)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedPlan == .yearly
                            ? Color(hex: "a78bfa")
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - No Payment Text
    
    private var noPaymentText: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "a78bfa"))
            
            Text("NO PAYMENT NOW")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.8))
        }
        .padding(.top, 8)
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            ZStack {
                // Button background
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "a78bfa"), Color(hex: "ec4899")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 60)
                
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("CONTINUE FOR FREE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(isPurchasing)
        .padding(.top, 8)
    }
    
    // MARK: - Footer Links
    
    private var footerLinks: some View {
        HStack(spacing: 24) {
            Button("Restore") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.white.opacity(0.5))
            
            Button("Terms of use") {
                // Open terms
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.white.opacity(0.5))
            
            Button("Privacy Policy") {
                // Open privacy
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.white.opacity(0.5))
        }
        .padding(.top, 16)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        guard !animationStarted else { return }
        animationStarted = true
        
        // Delay before starting animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Animate photos count
            animateCount(from: 678, to: targetPhotos, duration: 2.5) { value in
                photosCount = value
            }
            
            // Animate emails count
            animateCount(from: 326, to: targetEmails, duration: 2.5) { value in
                emailsCount = value
            }
            
            // Animate progress
            withAnimation(.easeInOut(duration: 2.5)) {
                progressPercent = targetPercent
            }
        }
    }
    
    private func animateCount(from start: Int, to end: Int, duration: Double, update: @escaping (Int) -> Void) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        let difference = start - end
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(steps)
                // Ease out curve
                let easedProgress = 1 - pow(1 - progress, 3)
                let currentValue = start - Int(Double(difference) * easedProgress)
                withAnimation(.linear(duration: stepDuration)) {
                    update(currentValue)
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    private func purchase() async {
        let productId: SubscriptionService.ProductID = selectedPlan == .weekly ? .weekly : .yearly
        guard let product = subscriptionService.product(for: productId) else {
            // Fallback if StoreKit products not loaded
            dismiss()
            return
        }
        
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
