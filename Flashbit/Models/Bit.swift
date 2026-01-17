import Foundation

/// A bite-sized news update
struct Bit: Identifiable, Codable {
    let id: UUID
    let headline: String
    let summary: String
    let category: BitCategory
    let source: String
    let publishedAt: Date
    let imageURL: URL?
    let articleURL: URL?

    init(
        id: UUID = UUID(),
        headline: String,
        summary: String,
        category: BitCategory,
        source: String,
        publishedAt: Date = Date(),
        imageURL: URL? = nil,
        articleURL: URL? = nil
    ) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.category = category
        self.source = source
        self.publishedAt = publishedAt
        self.imageURL = imageURL
        self.articleURL = articleURL
    }
}

enum BitCategory: String, Codable, CaseIterable {
    case breaking = "Breaking"
    case tech = "Tech"
    case business = "Business"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case science = "Science"
    case health = "Health"
    case world = "World"

    var color: String {
        switch self {
        case .breaking: return "red"
        case .tech: return "blue"
        case .business: return "green"
        case .sports: return "orange"
        case .entertainment: return "purple"
        case .science: return "cyan"
        case .health: return "pink"
        case .world: return "indigo"
        }
    }
}
