import SwiftUI

struct WelcomeOverlay: View {
    let onStartOnboarding: () -> Void
    let onSkipOnboarding: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: AppConstants.welcomeIconSize, height: AppConstants.welcomeIconSize)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.welcomeIconCornerRadius))

                VStack(spacing: 12) {
                    Text("Welcome to Flashbit")
                        .font(.system(size: AppConstants.welcomeTitleFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)

                    Text("Swipe through bite-sized news")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: onStartOnboarding) {
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
                    .accessibilityHint("Starts the onboarding tutorial")

                    Button(action: onSkipOnboarding) {
                        Text("Skip, I'll figure it out")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .accessibilityHint("Skips the tutorial and goes to the feed")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome screen")
    }
}
