import SwiftUI

struct SavedBitCard: View {
    let bit: Bit
    @EnvironmentObject private var storage: StorageService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            Text(bit.category.rawValue.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())

            // Headline
            Text(bit.headline)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)

            // Summary
            Text(bit.smartSummary)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)

            // Source and remove button
            HStack {
                Text(bit.source)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button(action: {
                    withAnimation {
                        storage.removeBit(bit)
                    }
                }) {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(.red.opacity(0.8))
                }
                .accessibilityLabel("Remove from saved")
                .accessibilityHint("Removes \(bit.headline) from saved bits")
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bit.headline), \(bit.category.rawValue), \(bit.source)")
    }
}
