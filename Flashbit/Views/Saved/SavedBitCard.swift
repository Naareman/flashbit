import SwiftUI

struct SavedBitCard: View {
    let bit: Bit
    @ObservedObject private var storage = StorageService.shared

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
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)

            // Source and remove button
            HStack {
                Text(bit.source)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button(action: {
                    withAnimation {
                        storage.removeBit(bit)
                    }
                }) {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}
