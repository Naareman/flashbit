import SwiftUI
import UIKit

struct SwipeableFeedView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject private var storage: StorageService
    @State private var currentIndex: Int = 0
    @State private var toastMessage: String? = nil
    @State private var toastIcon: String = "bookmark.fill"

    // Bits to display for this session (captured at load time)
    @State private var sessionBits: [Bit] = []
    @State private var hasLoadedSession: Bool = false

    // Track which bits user viewed this session (marked as seen when session ends)
    @State private var sessionViewedIndices: Set<Int> = []

    // Onboarding state
    // -1: Welcome screen (start here for first-time users)
    // 0: Tap right for next
    // 1: Tap left to go back
    // 2: Double-tap to save
    // 3: Point to Saved tab -> completes when tapped
    @State private var onboardingStep: Int = -1
    @State private var pulseAnimation: Bool = false

    private var showWelcomeScreen: Bool {
        storage.hasCompletedOnboarding == false && onboardingStep == -1
    }

    private var isOnboarding: Bool {
        storage.hasCompletedOnboarding == false && onboardingStep >= 0 && onboardingStep < 4
    }

    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    // Static articles for onboarding (independent from real news)
    private static let onboardingArticles: [Bit] = [
        Bit(
            headline: "Welcome to Flashbit",
            summary: "Swipe through bite-sized news updates",
            category: .tech,
            source: "Flashbit",
            publishedAt: Date(),
            articleURL: URL(string: "https://example.com")
        ),
        Bit(
            headline: "Tap the title to read full article",
            summary: "Double-tap anywhere to save",
            category: .world,
            source: "Flashbit",
            publishedAt: Date(),
            articleURL: URL(string: "https://example.com")
        ),
        Bit(
            headline: "Now save this bit and check your Saved tab",
            summary: "",
            category: .entertainment,
            source: "Flashbit",
            publishedAt: Date(),
            articleURL: URL(string: "https://example.com")
        )
    ]

    // Bits to display - uses onboarding articles when in tutorial mode
    private var displayBits: [Bit] {
        if !storage.hasCompletedOnboarding && onboardingStep >= 0 {
            return Self.onboardingArticles
        }
        return sessionBits
    }

    // Total items including the "caught up" card at the end
    private var totalItems: Int {
        displayBits.count + 1
    }

    private var isOnCaughtUpCard: Bool {
        currentIndex >= displayBits.count
    }

    // Remaining bits count for display
    private var remainingBitsCount: Int {
        max(0, displayBits.count - currentIndex - 1)
    }

    private var remainingBitsText: String {
        if remainingBitsCount > 50 {
            return "+50 bits left"
        } else if remainingBitsCount == 1 {
            return "1 bit left"
        } else {
            return "\(remainingBitsCount) bits left"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if !hasLoadedSession && !isOnboarding {
                    loadingView
                } else if displayBits.isEmpty || isOnCaughtUpCard {
                    CaughtUpCard()
                } else {
                    BitCardView(bit: displayBits[currentIndex], isInteractive: !isOnboarding)
                        .id(currentIndex)
                        .transition(.opacity)
                }

                // Tap zones - handles both single and double taps (only on article cards)
                // Excludes bottom area to allow headline tap to open article
                if !displayBits.isEmpty && !isOnCaughtUpCard {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) { saveBit() }
                                .onTapGesture { handleLeftTap() }

                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) { saveBit() }
                                .onTapGesture { handleRightTap() }
                        }

                        Color.clear
                            .frame(height: AppConstants.bottomExcludedTapZoneHeight)
                            .allowsHitTesting(false)
                    }
                }

                // Progress bar and remaining counter
                if !displayBits.isEmpty && !isOnCaughtUpCard {
                    VStack {
                        HStack {
                            FeedProgressBar(totalItems: totalItems, currentIndex: currentIndex, maxSegments: AppConstants.maxProgressSegments)

                            if !isOnboarding && !isOnCaughtUpCard {
                                Text(remainingBitsText)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        Spacer()
                    }
                    .padding(.top, AppConstants.progressBarTopPadding)
                }

                // Toast message
                if let message = toastMessage {
                    ToastView(message: message, icon: toastIcon)
                }

                // Interactive onboarding overlay
                if isOnboarding && !displayBits.isEmpty {
                    OnboardingOverlay(step: onboardingStep, pulseAnimation: $pulseAnimation)
                }

                // Welcome screen for first-time users
                if showWelcomeScreen && hasLoadedSession {
                    WelcomeOverlay(
                        onStartOnboarding: { withAnimation { onboardingStep = 0 } },
                        onSkipOnboarding: { storage.completeOnboarding() }
                    )
                }
            }
        }
        .task {
            // 0. If user increased cache limit, clear fetch times to force re-fetch
            if storage.needsRefetchAfterLimitIncrease {
                storage.needsRefetchAfterLimitIncrease = false
                storage.clearLastFetchTimes()
            }

            // 1. Show cached bits immediately so user can start swiping
            let hadCache = viewModel.loadCachedBits()
            if hadCache {
                sessionBits = viewModel.unseenBits
                if !sessionBits.isEmpty {
                    sessionViewedIndices.insert(0)
                }
            }
            hasLoadedSession = true

            // 2. Fetch fresh content in background, append new unseen bits as they arrive
            await viewModel.fetchFreshBits { [self] newBits in
                if sessionBits.isEmpty {
                    // No cached content was available — this is the first batch
                    sessionBits = newBits
                    if !sessionBits.isEmpty {
                        sessionViewedIndices.insert(0)
                    }
                } else {
                    // Append new bits after the current position so feed grows while swiping
                    let existingIDs = Set(sessionBits.map { $0.id })
                    let toAdd = newBits.filter { !existingIDs.contains($0.id) }
                    if !toAdd.isEmpty {
                        sessionBits.append(contentsOf: toAdd)
                    }
                }
            }

            // 3. If still empty after everything, try unseen from whatever we have
            if sessionBits.isEmpty {
                sessionBits = viewModel.unseenBits
                if !sessionBits.isEmpty {
                    sessionViewedIndices.insert(0)
                }
            }
        }
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
            heavyImpact.prepare()
            startPulseAnimation()
        }
        .onDisappear {
            markSessionBitsAsSeen()
        }
        .onChange(of: storage.hasCompletedOnboarding) { _, newValue in
            if !newValue {
                onboardingStep = -1
                currentIndex = 0
                startPulseAnimation()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if !storage.hasCompletedOnboarding && onboardingStep == 3 && newTab == .saved {
                storage.showOnboardingComplete = true
                storage.completeOnboarding()
            }
            if newTab != .feed {
                markSessionBitsAsSeen()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: AppConstants.pulseAnimationDuration).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    private func handleRightTap() {
        if isOnboarding && onboardingStep == 0 {
            withAnimation {
                onboardingStep = 1
            }
            goToNext()
        } else if isOnboarding && onboardingStep == 1 {
            goToNext()
        } else {
            goToNext()
        }
    }

    private func handleLeftTap() {
        if isOnboarding && onboardingStep == 1 {
            withAnimation {
                onboardingStep = 2
            }
            goToPrevious()
        } else {
            goToPrevious()
        }
    }

    private func refreshFeed() async {
        currentIndex = 0
        await viewModel.refreshBits { newBits in
            let existingIDs = Set(sessionBits.map { $0.id })
            let toAdd = newBits.filter { !existingIDs.contains($0.id) }
            if !toAdd.isEmpty {
                sessionBits.append(contentsOf: toAdd)
            }
        }
    }

    private func goToNext() {
        if currentIndex < totalItems - 1 {
            withAnimation(.easeInOut(duration: AppConstants.navigationAnimationDuration)) {
                currentIndex += 1
            }
            lightImpact.impactOccurred()
            if currentIndex < sessionBits.count {
                sessionViewedIndices.insert(currentIndex)
            }
        } else {
            mediumImpact.impactOccurred()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: AppConstants.navigationAnimationDuration)) {
                currentIndex -= 1
            }
            lightImpact.impactOccurred()
        } else {
            mediumImpact.impactOccurred()
        }
    }

    private func saveBit() {
        guard !isOnCaughtUpCard, currentIndex < displayBits.count else { return }
        let bit = displayBits[currentIndex]

        if storage.isSaved(bit) {
            storage.removeBit(bit)
            mediumImpact.impactOccurred()
            showToast(message: "Unsaved bit", icon: "bookmark.slash")
        } else {
            storage.saveBit(bit)
            heavyImpact.impactOccurred()
            showToast(message: "Saved bit", icon: "bookmark.fill")

            if !storage.hasCompletedOnboarding && onboardingStep == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.onboardingDelay) {
                    withAnimation {
                        onboardingStep = 3
                    }
                }
            }
        }
    }

    private func markSessionBitsAsSeen() {
        for index in sessionViewedIndices {
            if index < sessionBits.count {
                viewModel.markAsSeen(sessionBits[index])
            }
        }
    }

    private func showToast(message: String, icon: String) {
        toastIcon = icon
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.toastDuration) {
            withAnimation {
                toastMessage = nil
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading bits...")
                .foregroundColor(.white.opacity(0.7))
        }
    }

}

#Preview {
    SwipeableFeedView(selectedTab: .constant(.feed))
        .environmentObject(StorageService.shared)
}
