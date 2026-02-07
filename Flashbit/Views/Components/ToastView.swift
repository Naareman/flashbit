import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String

    var body: some View {
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)

            Spacer()
        }
    }
}
