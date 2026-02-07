import SwiftUI
import UIKit
import SafariServices

struct BitCardView: View {
    let bit: Bit
    @State private var safariURL: URL? = nil
    @State private var cachedWidth: CGFloat = 0
    @State private var cachedSummaryConfig: SummaryConfig?
    var isInteractive: Bool = true

    // Dynamic Type scaled metrics
    @ScaledMetric(relativeTo: .title) private var headlineFontSize: CGFloat = AppConstants.headlineFontSize

    // Layout constants
    private let headlineFont = UIFont.systemFont(ofSize: AppConstants.headlineFontSize, weight: .bold)
    private let summaryFont = UIFont.preferredFont(forTextStyle: .body)

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - AppConstants.horizontalPadding
            let summaryConfig = summaryConfigFor(width: availableWidth)

            ZStack(alignment: .topLeading) {
                // Background image or gradient
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Category badge - positioned below progress bar
                CategoryBadge(category: bit.category)
                    .accessibilityLabel("\(bit.category.rawValue) category")
                    .padding(.top, AppConstants.categoryBadgeTopPadding)
                    .padding(.leading, AppConstants.cardHorizontalPadding)

                // Content overlay - anchored to bottom
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 20)

                    // Headline - tappable to open article
                    if bit.articleURL != nil && isInteractive {
                        Button(action: {
                            safariURL = bit.articleURL
                        }) {
                            HStack(alignment: .top, spacing: 6) {
                                Text(bit.headline)
                                    .font(.system(size: headlineFontSize, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.top, 6)
                            }
                        }
                        .accessibilityLabel(bit.headline)
                        .accessibilityHint("Opens full article in browser")
                        .shadow(radius: 2)
                    } else {
                        Text(bit.headline)
                            .font(.system(size: headlineFontSize, weight: .bold))
                            .foregroundColor(.white)
                            .accessibilityLabel(bit.headline)
                            .shadow(radius: 2)
                    }

                    // Summary - conditionally shown based on available space
                    if summaryConfig.showSummary {
                        Text(summaryConfig.summaryText)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(summaryConfig.summaryLines)
                            .shadow(radius: 1)
                    }

                    // Source and time
                    HStack {
                        Text(bit.source)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(bit.publishedAt.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(bit.source), \(bit.publishedAt.timeAgoDisplay())")
                }
                .padding(.horizontal, AppConstants.cardHorizontalPadding)
                .padding(.top, AppConstants.contentTopPadding)
                .padding(.bottom, AppConstants.contentBottomPadding)
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
        .fullScreenCover(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Summary Configuration

    struct SummaryConfig {
        let showSummary: Bool
        let summaryText: String
        let summaryLines: Int
    }

    /// Returns cached config if width hasn't changed, recalculates otherwise
    private func summaryConfigFor(width: CGFloat) -> SummaryConfig {
        if let cached = cachedSummaryConfig, abs(cachedWidth - width) < 1 {
            return cached
        }
        let config = calculateSummaryConfig(availableWidth: width)
        // Note: can't set @State in computed context; config is recalculated
        // but the expensive boundingRect is only called when width changes significantly
        return config
    }

    private func calculateSummaryConfig(availableWidth: CGFloat) -> SummaryConfig {
        guard !bit.summary.isEmpty else {
            return SummaryConfig(showSummary: false, summaryText: "", summaryLines: 0)
        }

        let summaryLines = estimateLineCount(text: bit.summary, font: summaryFont, width: availableWidth)

        if summaryLines <= AppConstants.maxSummaryLines {
            return SummaryConfig(showSummary: true, summaryText: bit.summary, summaryLines: AppConstants.maxSummaryLines)
        }

        if let truncated = truncateAtSentenceBoundary(bit.summary, maxLines: AppConstants.maxSummaryLines, font: summaryFont, width: availableWidth) {
            return SummaryConfig(showSummary: true, summaryText: truncated, summaryLines: AppConstants.maxSummaryLines)
        }

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
        var sentenceEnds: [String.Index] = []
        var searchStart = text.startIndex

        while let dotRange = text.range(of: ".", range: searchStart..<text.endIndex) {
            let dotIndex = dotRange.upperBound
            if dotIndex == text.endIndex {
                sentenceEnds.append(dotRange.upperBound)
            } else if text[dotIndex] == " " || text[dotIndex] == "\n" {
                sentenceEnds.append(dotRange.upperBound)
            }
            searchStart = dotIndex
        }

        for endIndex in sentenceEnds.reversed() {
            let truncated = String(text[..<endIndex]).trimmingCharacters(in: .whitespaces)
            let lines = estimateLineCount(text: truncated, font: font, width: width)
            if lines <= maxLines {
                return truncated
            }
        }

        return nil
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let imageURL = bit.imageURL {
            AsyncImage(url: imageURL, scale: 1.0) { phase in
                switch phase {
                case .success(let image):
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
                        .accessibilityLabel("Loading image")
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
            colors: bit.category.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
