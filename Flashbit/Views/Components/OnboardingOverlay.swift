import SwiftUI

struct OnboardingOverlay: View {
    let step: Int
    @Binding var pulseAnimation: Bool

    var body: some View {
        ZStack {
            dimBackground
                .ignoresSafeArea()
                .allowsHitTesting(false)

            promptContent
        }
    }

    @ViewBuilder
    private var dimBackground: some View {
        switch step {
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

    @ViewBuilder
    private var promptContent: some View {
        switch step {
        case 0:
            HStack {
                Spacer()
                onboardingPrompt(text: "Next bit")
                    .padding(.trailing, 40)
            }
            .allowsHitTesting(false)
            .accessibilityLabel("Tap the right side for the next bit")

        case 1:
            HStack {
                onboardingPrompt(text: "Previous bit")
                    .padding(.leading, 20)
                Spacer()
            }
            .allowsHitTesting(false)
            .accessibilityLabel("Tap the left side for the previous bit")

        case 2:
            onboardingPrompt(text: "Double-tap to save")
                .allowsHitTesting(false)
                .accessibilityLabel("Double-tap anywhere to save this bit")

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
            .accessibilityLabel("Tap the Saved tab below to find your saved articles")

        default:
            EmptyView()
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
}
