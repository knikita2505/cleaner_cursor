import SwiftUI

// MARK: - Feature Tip View
/// Модальное окно с подсказками для функционала

struct FeatureTipView: View {
    
    // MARK: - Properties
    
    let tipData: FeatureTipData
    let onDismiss: () -> Void
    
    @State private var currentPage: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(tipData.pages.enumerated()), id: \.element.id) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicator
                pageIndicator
                
                // Button
                actionButton
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button {
                HapticManager.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Page View
    
    private func pageView(_ page: FeatureTipPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: page.icon)
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            // Description
            Text(page.description)
                .font(AppFonts.bodyL)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<tipData.pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppColors.accentBlue : AppColors.textTertiary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            HapticManager.lightImpact()
            if currentPage < tipData.pages.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                onDismiss()
            }
        } label: {
            Text(currentPage < tipData.pages.count - 1 ? "Next" : "Got it!")
                .font(AppFonts.buttonPrimary)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.accentLilac],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Preview

#Preview {
    FeatureTipView(tipData: .cleanPhotos) {
        print("Dismissed")
    }
}
