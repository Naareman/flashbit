import SwiftUI
import UIKit
import SafariServices

struct BitCardView: View {
    let bit: Bit
    @State private var showingSafari = false

    // Layout constants
    private let headlineFont = UIFont.systemFont(ofSize: 28, weight: .bold)
    private let summaryFont = UIFont.preferredFont(forTextStyle: .body)
    private let horizontalPadding: CGFloat = 48 // 24 on each side
    private let maxSummaryLines = 5

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - horizontalPadding
            let summaryConfig = calculateSummaryConfig(availableWidth: availableWidth)

            ZStack(alignment: .topLeading) {
                // Background image or gradient
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Category badge - positioned below progress bar
                CategoryBadge(category: bit.category)
                    .padding(.top, 70) // Below the progress bar area
                    .padding(.leading, 24)

                // Content overlay - anchored to bottom
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 20) // Allows content to expand upward

                    // Headline
                    Text(bit.headline)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)

                    // Summary - conditionally shown based on available space
                    if summaryConfig.showSummary {
                        Text(summaryConfig.summaryText)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(summaryConfig.summaryLines)
                            .shadow(radius: 1)
                    }

                    // Source, time, and read button
                    HStack {
                        Text(bit.source)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        // Read full article button
                        if bit.articleURL != nil {
                            Button(action: {
                                showingSafari = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("Read")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }

                        Text(bit.publishedAt.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 100) // Start below category badge area
                .padding(.bottom, 100) // Fixed padding above tab bar
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
        .fullScreenCover(isPresented: $showingSafari) {
            if let url = bit.articleURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Summary Configuration

    private struct SummaryConfig {
        let showSummary: Bool
        let summaryText: String
        let summaryLines: Int
    }

    private func calculateSummaryConfig(availableWidth: CGFloat) -> SummaryConfig {
        // Check if summary is empty
        guard !bit.summary.isEmpty else {
            return SummaryConfig(showSummary: false, summaryText: "", summaryLines: 0)
        }

        let summaryLines = estimateLineCount(text: bit.summary, font: summaryFont, width: availableWidth)

        // Summary fits completely within max lines
        if summaryLines <= maxSummaryLines {
            return SummaryConfig(showSummary: true, summaryText: bit.summary, summaryLines: maxSummaryLines)
        }

        // Summary is too long - try truncating at sentence boundary
        if let truncated = truncateAtSentenceBoundary(bit.summary, maxLines: maxSummaryLines, font: summaryFont, width: availableWidth) {
            return SummaryConfig(showSummary: true, summaryText: truncated, summaryLines: maxSummaryLines)
        }

        // No good sentence boundary - hide summary entirely
        return SummaryConfig(showSummary: false, summaryText: "", summaryLines: 0)
    }

    private func estimateLineCount(text: String, font: UIFont, width: CGFloat) -> Int {
        guard !text.isEmpty, width > 0 else { return 0 }

        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let boundingRect = text.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return Int(ceil(boundingRect.height / font.lineHeight))
    }

    private func truncateAtSentenceBoundary(_ text: String, maxLines: Int, font: UIFont, width: CGFloat) -> String? {
        // Find all sentence-ending positions (dots followed by space or end)
        var sentenceEnds: [String.Index] = []
        var searchStart = text.startIndex

        while let dotRange = text.range(of: ".", range: searchStart..<text.endIndex) {
            let dotIndex = dotRange.upperBound
            // Check if it's end of string or followed by space (actual sentence end)
            if dotIndex == text.endIndex {
                sentenceEnds.append(dotRange.upperBound)
            } else if text[dotIndex] == " " || text[dotIndex] == "\n" {
                sentenceEnds.append(dotRange.upperBound)
            }
            searchStart = dotIndex
        }

        // Try each sentence boundary from longest to shortest
        for endIndex in sentenceEnds.reversed() {
            let truncated = String(text[..<endIndex]).trimmingCharacters(in: .whitespaces)
            let lines = estimateLineCount(text: truncated, font: font, width: width)
            if lines <= maxLines {
                return truncated
            }
        }

        return nil // No suitable sentence boundary found
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

// MARK: - Safari View Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemBlue
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
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
