import SwiftUI
import UIKit

struct SwipeableFeedView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = FeedViewModel()
    @ObservedObject private var storage = StorageService.shared
    @State private var currentIndex: Int = 0
    @State private var toastMessage: String? = nil
    @State private var toastIcon: String = "bookmark.fill"

    // Onboarding state (4 steps: 0-3)
    // 0: Tap right for next
    // 1: Tap left to go back
    // 2: Double-tap to save
    // 3: Point to Saved tab → completes when tapped
    @State private var onboardingStep: Int = 0
    @State private var pulseAnimation: Bool = false

    private var isOnboarding: Bool {
        storage.hasCompletedOnboarding == false && onboardingStep < 4
    }

    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    // Total items including the "caught up" card at the end
    private var totalItems: Int {
        viewModel.bits.count + 1
    }

    private var isOnCaughtUpCard: Bool {
        currentIndex == viewModel.bits.count
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.bits.isEmpty {
                    loadingView
                } else if isOnCaughtUpCard {
                    // "You're all caught up" as its own story card
                    caughtUpCard
                } else {
                    // Current news card
                    BitCardView(bit: viewModel.bits[currentIndex])
                        .id(currentIndex)
                        .transition(.opacity)
                }

                // Tap zones - handles both single and double taps (only on article cards)
                if !viewModel.bits.isEmpty && !isOnCaughtUpCard {
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
                }

                // Progress bar (Instagram Stories style) - only show when we have bits
                if !viewModel.bits.isEmpty {
                    VStack {
                        progressBar
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
                if isOnboarding && !viewModel.bits.isEmpty {
                    onboardingOverlay(geometry: geometry)
                }
            }
        }
        .task {
            await viewModel.loadBits()
        }
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
            heavyImpact.prepare()
            startPulseAnimation()
        }
        .onChange(of: storage.hasCompletedOnboarding) { _, newValue in
            if !newValue {
                // Reset onboarding when user chooses to see it again
                onboardingStep = 0
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
        guard !isOnCaughtUpCard else { return }
        let bit = viewModel.bits[currentIndex]

        // Check if already saved
        if storage.isSaved(bit) {
            // Already saved - remove it
            storage.removeBit(bit)
            mediumImpact.impactOccurred()
            showToast(message: "Unsaved", icon: "bookmark.slash")
        } else {
            // Save the bit
            storage.saveBit(bit)
            heavyImpact.impactOccurred()
            showToast(message: "Saved!", icon: "bookmark.fill")

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

                Text("You're all caught up!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Now you are up to date")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 16) {
                    // Go Back button
                    Button(action: {
                        goToPrevious()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Go Back")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }

                    // Start Over button
                    Button(action: {
                        withAnimation {
                            currentIndex = 0
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start Over")
                        }
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(25)
                    }
                }
                .padding(.top, 16)

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
                // Right side - "Tap here for next"
                HStack {
                    Spacer()
                    onboardingPrompt(text: "Tap here", subtext: "for next bit")
                        .padding(.trailing, 40)
                }
                .allowsHitTesting(false)

            case 1:
                // Left side - "Tap here to go back"
                HStack {
                    onboardingPrompt(text: "Tap here", subtext: "to go back")
                        .padding(.leading, 20)
                    Spacer()
                }
                .allowsHitTesting(false)

            case 2:
                // Center - "Double-tap to save"
                onboardingPrompt(text: "Double-tap", subtext: "anywhere to save")
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

    private func onboardingPrompt(text: String, subtext: String) -> some View {
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

            Text(subtext)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
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
