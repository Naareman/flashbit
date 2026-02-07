import SwiftUI

struct CategoryBadge: View {
    let category: BitCategory

    var body: some View {
        Text(category.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .accessibilityLabel("\(category.rawValue) category")
    }
}
