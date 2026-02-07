import SwiftUI
import UIKit

struct SwipeableFeedView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = FeedViewModel()
    @ObservedObject private var storage = StorageService.shared
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
            summary: "One bit = One story",
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
                    caughtUpCard
                } else {
                    BitCardView(bit: displayBits[currentIndex])
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
                            progressBar

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
                    toastView(message: message, icon: toastIcon)
                }

                // Interactive onboarding overlay
                if isOnboarding && !displayBits.isEmpty {
                    onboardingOverlay(geometry: geometry)
                }

                // Welcome screen for first-time users
                if showWelcomeScreen && hasLoadedSession {
                    welcomeOverlay
                }
            }
        }
        .task {
            await viewModel.loadBits()
            sessionBits = viewModel.unseenBits
            if !sessionBits.isEmpty {
                sessionViewedIndices.insert(0)
            }
            hasLoadedSession = true
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
        await viewModel.refreshBits()
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

    // Welcome screen for first-time users
    private var welcomeOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppConstants.welcomeIconSize, height: AppConstants.welcomeIconSize)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.welcomeIconCornerRadius))

                VStack(spacing: 12) {
                    Text("Welcome to Flashbit")
                        .font(.system(size: AppConstants.welcomeTitleFontSize, weight: .bold))
                        .foregroundColor(.white)

                    Text("One bit = One story")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            onboardingStep = 0
                        }
                    }) {
                        Text("Show me how it works")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        storage.completeOnboarding()
                    }) {
                        Text("Skip, I'll figure it out")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }

    // "You're all caught up" as a full story card
    private var caughtUpCard: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: AppConstants.caughtUpIconSize, height: AppConstants.caughtUpIconSize)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: AppConstants.caughtUpBoltSize))
                        .foregroundColor(.white)
                }

                Text("That's everything for now")
                    .font(.system(size: AppConstants.caughtUpTitleFontSize, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
                Spacer()
            }
            .padding(.bottom, AppConstants.contentBottomPadding)
        }
    }

    private func toastView(message: String, icon: String) -> some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(message)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(25)

            Spacer()
        }
    }

    // Interactive onboarding overlay
    private func onboardingOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            Group {
                switch onboardingStep {
                case 0:
                    HStack(spacing: 0) {
                        Color.black.opacity(0.25)
                        Color.clear
                    }
                case 1:
                    HStack(spacing: 0) {
                        Color.clear
                        Color.black.opacity(0.25)
                    }
                case 2:
                    Color.black.opacity(0.3)
                case 3:
                    VStack(spacing: 0) {
                        Color.black.opacity(0.85)
                        Color.black.opacity(0.15)
                            .frame(height: AppConstants.tabBarHeight)
                    }
                default:
                    Color.clear
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            switch onboardingStep {
            case 0:
                HStack {
                    Spacer()
                    onboardingPrompt(text: "Next bit")
                        .padding(.trailing, 40)
                }
                .allowsHitTesting(false)

            case 1:
                HStack {
                    onboardingPrompt(text: "Previous bit")
                        .padding(.leading, 20)
                    Spacer()
                }
                .allowsHitTesting(false)

            case 2:
                onboardingPrompt(text: "Double-tap to save")
                    .allowsHitTesting(false)

            case 3:
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("Find your saved articles")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Image(systemName: "arrow.down")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(pulseAnimation ? 1.3 : 0.9)
                            .offset(y: pulseAnimation ? 6 : -6)
                    }
                    .padding(.bottom, 95)
                }
                .allowsHitTesting(false)

            default:
                EmptyView()
            }
        }
    }

    private func onboardingPrompt(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
                .scaleEffect(pulseAnimation ? 1.2 : 0.85)

            Text(text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(pulseAnimation ? 1.05 : 0.95)
        }
        .opacity(pulseAnimation ? 1.0 : 0.6)
    }

    // Max number of progress segments to display
    private let maxProgressSegments = AppConstants.maxProgressSegments

    private var articlesPerSegment: Int {
        max(1, Int(ceil(Double(totalItems) / Double(maxProgressSegments))))
    }

    private var progressSegmentCount: Int {
        min(totalItems, maxProgressSegments)
    }

    private var currentProgressSegment: Int {
        currentIndex / articlesPerSegment
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<progressSegmentCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentProgressSegment ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 3)
            }
        }
    }
}

#Preview {
    SwipeableFeedView(selectedTab: .constant(.feed))
}
