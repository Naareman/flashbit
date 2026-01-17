import SwiftUI

struct BitCardView: View {
    let bit: Bit

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background image or gradient
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Content overlay
                VStack(alignment: .leading, spacing: 16) {
                    // Category badge
                    CategoryBadge(category: bit.category)
                        .padding(.top, 60)

                    Spacer()

                    // Headline
                    Text(bit.smartHeadline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .shadow(radius: 2)

                    // Summary (intelligently truncated to fit)
                    Text(bit.smartSummary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(4)
                        .shadow(radius: 1)

                    // Source and time
                    HStack {
                        Text(bit.source)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(bit.publishedAt.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 100) // Extra padding to stay above tab bar
                .background(
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.7), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let imageURL = bit.imageURL {
            // Request higher resolution by using scale factor
            AsyncImage(url: imageURL, scale: 1.0) { phase in
                switch phase {
                case .success(let image):
                    // Use fill to cover the area, with clipping to maintain aspect ratio
                    // This crops overflow rather than stretching
                    GeometryReader { geo in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                case .failure(_):
                    placeholderGradient
                case .empty:
                    placeholderGradient
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    placeholderGradient
                }
            }
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: gradientColors(for: bit.category),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func gradientColors(for category: BitCategory) -> [Color] {
        switch category {
        case .breaking: return [.red, .orange]
        case .tech: return [.blue, .purple]
        case .business: return [.green, .teal]
        case .sports: return [.orange, .yellow]
        case .entertainment: return [.purple, .pink]
        case .science: return [.cyan, .blue]
        case .health: return [.pink, .red]
        case .world: return [.indigo, .blue]
        }
    }
}

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
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    BitCardView(bit: Bit(
        headline: "Apple Announces Revolutionary New AI Features for iPhone",
        summary: "The tech giant unveiled a suite of AI-powered features that will transform how users interact with their devices.",
        category: .tech,
        source: "TechCrunch"
    ))
}
