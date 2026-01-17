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
    // 3: Point to Saved tab → completes when tapped
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
                    // Show loading until session bits are loaded (skip for onboarding)
                    loadingView
                } else if displayBits.isEmpty || isOnCaughtUpCard {
                    // "You're all caught up" as its own story card
                    caughtUpCard
                } else {
                    // Current news card
                    BitCardView(bit: displayBits[currentIndex])
                        .id(currentIndex)
                        .transition(.opacity)
                }

                // Tap zones - handles both single and double taps (only on article cards)
                // Excludes bottom 280pt to allow headline tap to open article
                if !displayBits.isEmpty && !isOnCaughtUpCard {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            // Left tap zone - previous
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) { saveBit() }
                                .onTapGesture { handleLeftTap() }

                            // Right tap zone - next
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) { saveBit() }
                                .onTapGesture { handleRightTap() }
                        }

                        // Bottom area excluded from tap zones (allows headline to be tapped)
                        Color.clear
                            .frame(height: 280)
                            .allowsHitTesting(false)
                    }
                }

                // Progress bar and remaining counter - only show when viewing bits (not on caught up card)
                if !displayBits.isEmpty && !isOnCaughtUpCard {
                    VStack {
                        HStack {
                            progressBar

                            // Remaining bits counter (hide during onboarding)
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
                    .padding(.top, 44)
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
            // Capture unseen bits for this session
            sessionBits = viewModel.unseenBits
            // Track first bit as viewed (will be marked as seen when session ends)
            if !sessionBits.isEmpty {
                sessionViewedIndices.insert(0)
            }
            // Mark session as loaded (prevents showing "caught up" before load completes)
            hasLoadedSession = true
        }
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
            heavyImpact.prepare()
            startPulseAnimation()
        }
        .onDisappear {
            // Mark all viewed bits as seen when leaving the feed
            markSessionBitsAsSeen()
        }
        .onChange(of: storage.hasCompletedOnboarding) { _, newValue in
            if !newValue {
                // Reset onboarding when user chooses to see it again
                onboardingStep = -1
                currentIndex = 0
                startPulseAnimation()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // If user taps Saved tab during onboarding step 3, complete and show success
            if !storage.hasCompletedOnboarding && onboardingStep == 3 && newTab == .saved {
                storage.showOnboardingComplete = true
                storage.completeOnboarding()
            }
            // Mark viewed bits as seen when switching away from feed
            if newTab != .feed {
                markSessionBitsAsSeen()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    private func handleRightTap() {
        if isOnboarding && onboardingStep == 0 {
            // First step: user tapped right for next
            withAnimation {
                onboardingStep = 1
            }
            goToNext()
        } else if isOnboarding && onboardingStep == 1 {
            // Second step: waiting for left tap, but they tapped right
            goToNext()
        } else {
            goToNext()
        }
    }

    private func handleLeftTap() {
        if isOnboarding && onboardingStep == 1 {
            // Second step: user tapped left for previous
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
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
            }
            lightImpact.impactOccurred()
            // Track this bit as viewed (will be marked as seen when session ends)
            if currentIndex < sessionBits.count {
                sessionViewedIndices.insert(currentIndex)
            }
        } else {
            // At the very end (past caught up card)
            mediumImpact.impactOccurred()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex -= 1
            }
            lightImpact.impactOccurred()
        } else {
            // At the beginning
            mediumImpact.impactOccurred()
        }
    }

    private func saveBit() {
        guard !isOnCaughtUpCard, currentIndex < displayBits.count else { return }
        let bit = displayBits[currentIndex]

        // Check if already saved
        if storage.isSaved(bit) {
            // Already saved - remove it
            storage.removeBit(bit)
            mediumImpact.impactOccurred()
            showToast(message: "Unsaved bit", icon: "bookmark.slash")
        } else {
            // Save the bit
            storage.saveBit(bit)
            heavyImpact.impactOccurred()
            showToast(message: "Saved bit", icon: "bookmark.fill")

            // Progress onboarding if on step 2 - quickly point to Saved tab
            if !storage.hasCompletedOnboarding && onboardingStep == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        onboardingStep = 3
                    }
                }
            }
        }
    }

    /// Mark all viewed bits as seen (called when session ends)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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

                // App icon
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                VStack(spacing: 12) {
                    Text("Welcome to Flashbit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("One bit = One story")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Start tutorial button
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

                    // Skip button
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
            // Gradient background
            LinearGradient(
                colors: [.purple, .blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App icon / lightning bolt
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                Text("That's everything for now")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
                Spacer()
            }
            .padding(.bottom, 100)
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
            // Tint overlay
            Group {
                switch onboardingStep {
                case 0:
                    // Dim left side, highlight right
                    HStack(spacing: 0) {
                        Color.black.opacity(0.25)
                        Color.clear
                    }
                case 1:
                    // Dim right side, highlight left
                    HStack(spacing: 0) {
                        Color.clear
                        Color.black.opacity(0.25)
                    }
                case 2:
                    // Light overlay for double-tap
                    Color.black.opacity(0.3)
                case 3:
                    // Very dark overlay with cutout for tab bar area
                    VStack(spacing: 0) {
                        Color.black.opacity(0.85)
                        // Leave bottom 85pt lighter for tab bar
                        Color.black.opacity(0.15)
                            .frame(height: 85)
                    }
                default:
                    Color.clear
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Positioned instruction based on step
            switch onboardingStep {
            case 0:
                // Right side - "Next bit"
                HStack {
                    Spacer()
                    onboardingPrompt(text: "Next bit")
                        .padding(.trailing, 40)
                }
                .allowsHitTesting(false)

            case 1:
                // Left side - "Previous bit"
                HStack {
                    onboardingPrompt(text: "Previous bit")
                        .padding(.leading, 20)
                    Spacer()
                }
                .allowsHitTesting(false)

            case 2:
                // Center - "Double-tap to save"
                onboardingPrompt(text: "Double-tap to save")
                    .allowsHitTesting(false)

            case 3:
                // Point to Saved tab at bottom - text closer to tab bar
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
    private let maxProgressSegments = 20

    // How many articles each progress segment represents
    private var articlesPerSegment: Int {
        max(1, Int(ceil(Double(totalItems) / Double(maxProgressSegments))))
    }

    // Total number of progress segments to show
    private var progressSegmentCount: Int {
        min(totalItems, maxProgressSegments)
    }

    // Which progress segment is currently active
    private var currentProgressSegment: Int {
        currentIndex / articlesPerSegment
    }

    // Instagram Stories style progress bar (grouped into max 20 segments)
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
