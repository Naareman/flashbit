import SwiftUI

struct CaughtUpCard: View {
    var body: some View {
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
                    .accessibilityAddTraits(.isHeader)

                Spacer()
                Spacer()
            }
            .padding(.bottom, AppConstants.contentBottomPadding)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're all caught up. That's everything for now.")
    }
}
