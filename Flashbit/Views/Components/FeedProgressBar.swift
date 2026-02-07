import SwiftUI

struct FeedProgressBar: View {
    let totalItems: Int
    let currentIndex: Int
    let maxSegments: Int

    private var articlesPerSegment: Int {
        max(1, Int(ceil(Double(totalItems) / Double(maxSegments))))
    }

    private var segmentCount: Int {
        min(totalItems, maxSegments)
    }

    private var currentSegment: Int {
        guard totalItems > 0 else { return 0 }
        return min(currentIndex * segmentCount / totalItems, segmentCount - 1)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<segmentCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentSegment ? Color.white : Color.white.opacity(0.4))
                    .frame(height: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Article \(currentIndex + 1) of \(totalItems)")
    }
}
