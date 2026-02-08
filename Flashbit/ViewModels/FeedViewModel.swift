import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    @Published var bits: [Bit] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var errorMessage: String?

    private let newsService: NewsService
    private let storage: StorageService

    init(newsService: NewsService = NewsService(), storage: StorageService? = nil) {
        self.newsService = newsService
        self.storage = storage ?? .shared
    }

    /// Returns only the bits the user hasn't seen yet
    var unseenBits: [Bit] {
        bits.filter { !storage.isSeen($0) }
    }

    /// Mark a bit as seen
    func markAsSeen(_ bit: Bit) {
        storage.markAsSeen(bit)
        objectWillChange.send() // Trigger UI update
    }

    /// Loads cached bits immediately and returns true if there were cached bits to show
    func loadCachedBits() -> Bool {
        if !storage.cachedBits.isEmpty {
            bits = filterBySelectedCategories(storage.cachedBits)
            return true
        }
        return false
    }

    /// Fetches fresh bits from RSS feeds in the background.
    /// Calls onNewBits each time a feed completes with newly unseen bits.
    func fetchFreshBits(onNewBits: @escaping @MainActor ([Bit]) -> Void) async {
        isLoading = bits.isEmpty
        error = nil
        errorMessage = nil

        await newsService.fetchBitsProgressively { [weak self] updatedBits in
            guard let self = self else { return }
            let filtered = self.filterBySelectedCategories(updatedBits)
            let newUnseen = filtered.filter { !self.storage.isSeen($0) }

            // Find bits that weren't in the previous set
            let previousIDs = Set(self.bits.map { $0.stableIdentifier })
            let brandNew = newUnseen.filter { !previousIDs.contains($0.stableIdentifier) }

            self.bits = filtered
            self.isLoading = false

            if !brandNew.isEmpty {
                onNewBits(brandNew)
            }
        }

        // If still no bits after all feeds, fall back to mock data
        if bits.isEmpty {
            bits = filterBySelectedCategories(Self.mockBits)
            let unseen = bits.filter { !storage.isSeen($0) }
            if !unseen.isEmpty {
                onNewBits(unseen)
            } else {
                error = URLError(.cannotLoadFromNetwork)
                errorMessage = "Unable to load news. Check your connection."
            }
        }

        isLoading = false
    }

    func refreshBits(onNewBits: @escaping @MainActor ([Bit]) -> Void) async {
        isLoading = true
        await fetchFreshBits(onNewBits: onNewBits)
    }

    private func filterBySelectedCategories(_ bits: [Bit]) -> [Bit] {
        let selectedCategories = storage.selectedCategories
        return bits.filter { selectedCategories.contains($0.category) }
    }

    // Mock data - 10 diverse news items
    static let mockBits: [Bit] = [
        Bit(
            headline: "Apple Unveils Next-Generation AI Assistant",
            summary: "The tech giant announced a revolutionary AI system that understands context and learns from user behavior to provide personalized assistance.",
            category: .tech,
            source: "TechCrunch",
            imageURL: URL(string: "https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=800")
        ),
        Bit(
            headline: "Global Markets Rally on Economic Data",
            summary: "Stock markets worldwide saw significant gains following positive employment figures and inflation reports from major economies.",
            category: .business,
            source: "Bloomberg",
            imageURL: URL(string: "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800")
        ),
        Bit(
            headline: "Scientists Discover New Species in Deep Ocean",
            summary: "Marine biologists have identified over 50 previously unknown species during an expedition to the Pacific's deepest trenches.",
            category: .science,
            source: "Nature",
            imageURL: URL(string: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800")
        ),
        Bit(
            headline: "Championship Finals Set After Dramatic Semifinals",
            summary: "Two underdogs advance to the finals after stunning upsets that have fans buzzing about one of the most exciting playoffs in history.",
            category: .sports,
            source: "ESPN",
            imageURL: URL(string: "https://images.unsplash.com/photo-1461896836934-28d1909b1c19?w=800")
        ),
        Bit(
            headline: "New Study Links Sleep Quality to Longevity",
            summary: "Research spanning 20 years reveals that consistent sleep patterns may be more important than total hours of sleep for long-term health.",
            category: .health,
            source: "Medical News",
            imageURL: URL(string: "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800")
        ),
        Bit(
            headline: "Award-Winning Director Announces Surprise Project",
            summary: "The acclaimed filmmaker revealed a secret production that has been in development for three years, featuring an all-star ensemble cast.",
            category: .entertainment,
            source: "Variety",
            imageURL: URL(string: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800")
        ),
        Bit(
            headline: "Historic Climate Agreement Reached at Summit",
            summary: "World leaders have committed to unprecedented carbon reduction targets in a deal described as a turning point for global climate action.",
            category: .world,
            source: "Reuters",
            imageURL: URL(string: "https://images.unsplash.com/photo-1569163139599-0f4517e36f51?w=800")
        ),
        Bit(
            headline: "Breaking: Major Policy Announcement Expected",
            summary: "Officials are preparing to announce significant changes that could affect millions of citizens, with details expected within the hour.",
            category: .breaking,
            source: "AP News",
            imageURL: URL(string: "https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800")
        ),
        Bit(
            headline: "SpaceX Successfully Lands Starship After Orbital Flight",
            summary: "The massive rocket completed its first successful orbital mission and landed back at the launch site, marking a major milestone for space exploration.",
            category: .tech,
            source: "Space.com",
            imageURL: URL(string: "https://images.unsplash.com/photo-1516849841032-87cbac4d88f7?w=800")
        ),
        Bit(
            headline: "Astronomers Detect Signs of Life on Distant Exoplanet",
            summary: "Spectral analysis of an Earth-like planet's atmosphere reveals potential biosignatures that could indicate the presence of life.",
            category: .science,
            source: "NASA",
            imageURL: URL(string: "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=800")
        )
    ]
}
