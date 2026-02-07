import Foundation

/// A bite-sized news update
struct Bit: Identifiable, Codable {
    let id: UUID
    let headline: String
    let summary: String
    var aiSummary: String?
    let category: BitCategory
    let source: String
    let publishedAt: Date
    let imageURL: URL?
    let articleURL: URL?

    init(
        id: UUID = UUID(),
        headline: String,
        summary: String,
        aiSummary: String? = nil,
        category: BitCategory,
        source: String,
        publishedAt: Date = Date(),
        imageURL: URL? = nil,
        articleURL: URL? = nil
    ) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.aiSummary = aiSummary
        self.category = category
        self.source = source
        self.publishedAt = publishedAt
        self.imageURL = imageURL
        self.articleURL = articleURL
    }

    /// Returns the best available summary - AI-generated if available, otherwise smart truncation
    var smartSummary: String {
        if let ai = aiSummary, !ai.isEmpty {
            return ai
        }
        return summary.smartTruncate(maxLength: AppConstants.smartTruncateMaxLength)
    }

    /// Returns headline, truncated smartly if too long for 3 lines (~90 chars)
    var smartHeadline: String {
        headline.smartTruncate(maxLength: AppConstants.headlineTruncateMaxLength)
    }
}
