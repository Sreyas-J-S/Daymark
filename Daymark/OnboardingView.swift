import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    let pages = [
        OnboardingPage(
            title: "Daymark",
            subtitle: "Your day, organized.",
            description: "A premium, minimalist space designed to bring clarity, peace, and order to your daily schedule.",
            imageName: "checklist",
            gradient: Theme.primaryGradient
        ),
        OnboardingPage(
            title: "Stay on Track",
            subtitle: "Smart Reminders",
            description: "Set one-off or complex recurring reminders (daily, weekdays, weekly) so you never miss what's important.",
            imageName: "bell.badge.fill",
            gradient: Theme.warningGradient
        ),
        OnboardingPage(
            title: "Categorize",
            subtitle: "Neat & Structured",
            description: "Separate your life into Work, Study, Personal, or Shopping. Add subtasks to divide and conquer large goals.",
            imageName: "folder.fill",
            gradient: Theme.successGradient
        )
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Progress Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Theme.brandPrimary : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 24)
                
                // Content Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingCardView(page: pages[index], isAnimating: isAnimating)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Navigation / Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring()) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasCompletedOnboarding = true
                            }
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasCompletedOnboarding = true
                            }
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                    } else {
                        // Spacer helper to maintain height
                        Text("")
                            .font(.subheadline)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let gradient: LinearGradient
}

struct OnboardingCardView: View {
    let page: OnboardingPage
    var isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon Ring and Background Glow
            ZStack {
                Circle()
                    .fill(page.gradient.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 12)
                
                Circle()
                    .fill(page.gradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 54))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: isAnimating)
            
            // Typography Section
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.brandPrimary)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            .offset(y: isAnimating ? 0 : 30)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimating)
            
            Spacer()
        }
    }
}
