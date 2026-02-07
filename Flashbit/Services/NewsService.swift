import Foundation

actor NewsService: NewsServiceProtocol {
    private let session: URLSession
    private let rssParser = RSSParser()

    // RSS Feed URLs with source info
    struct FeedConfig {
        let url: String
        let source: String
        let category: BitCategory
    }

    private static let feeds: [FeedConfig] = [
        FeedConfig(url: "https://feeds.bbci.co.uk/news/rss.xml", source: "BBC News", category: .world),
        FeedConfig(url: "https://www.theguardian.com/world/rss", source: "The Guardian", category: .world),
        FeedConfig(url: "https://www.reutersagency.com/feed/?best-regions=europe&post_type=best", source: "Reuters", category: .world),
        FeedConfig(url: "https://techcrunch.com/feed/", source: "TechCrunch", category: .tech)
    ]

    // How many items to fetch per source on first launch
    private static let itemsPerSourceFirstFetch = AppConstants.itemsPerSourceFirstFetch

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    /// Fetches bite-sized news updates from RSS feeds
    /// On first fetch: gets 50 per source
    /// On subsequent fetches: gets only new articles since last fetch
    func fetchBits() async throws -> [Bit] {
        let storage = await MainActor.run { StorageService.shared }
        let isFirstFetch = await MainActor.run { storage.isFirstFetch }

        // Fetch all RSS feeds concurrently
        async let bbcBits = fetchRSSFeed(feed: Self.feeds[0], isFirstFetch: isFirstFetch)
        async let guardianBits = fetchRSSFeed(feed: Self.feeds[1], isFirstFetch: isFirstFetch)
        async let reutersBits = fetchRSSFeed(feed: Self.feeds[2], isFirstFetch: isFirstFetch)
        async let techCrunchBits = fetchRSSFeed(feed: Self.feeds[3], isFirstFetch: isFirstFetch)

        // Combine all results
        let allResults = await [bbcBits, guardianBits, reutersBits, techCrunchBits]
        var newBits: [Bit] = []
        var successCount = 0

        for result in allResults {
            switch result {
            case .success(let bits):
                newBits.append(contentsOf: bits)
                successCount += 1
            case .failure:
                continue
            }
        }

        // If all feeds failed, return cached data as fallback
        if successCount == 0 {
            let cached = await MainActor.run { storage.cachedBits }
            if !cached.isEmpty {
                return cached
            }
            // Last resort: return mock data
            return await MainActor.run {
                Array(FeedViewModel.mockBits.prefix(10))
            }
        }

        // Mark first fetch complete if this was the first time
        if isFirstFetch {
            await MainActor.run {
                storage.markFirstFetchComplete()
            }
        }

        // Update cache with new bits
        await MainActor.run {
            storage.updateCachedBits(with: newBits)
        }

        // Return all cached bits (sorted by date)
        return await MainActor.run { storage.cachedBits }
    }

    /// Fetches RSS feeds one by one, calling onBatchReady after each feed completes
    /// This allows showing articles progressively as they load
    func fetchBitsProgressively(onBatchReady: @escaping @MainActor ([Bit]) -> Void) async {
        let storage = await MainActor.run { StorageService.shared }
        let isFirstFetch = await MainActor.run { storage.isFirstFetch }

        // Fetch feeds concurrently but process results as they arrive
        await withTaskGroup(of: Result<[Bit], Error>.self) { group in
            for feed in Self.feeds {
                group.addTask {
                    await self.fetchRSSFeed(feed: feed, isFirstFetch: isFirstFetch)
                }
            }

            var successCount = 0
            for await result in group {
                switch result {
                case .success(let bits):
                    if !bits.isEmpty {
                        // Update cache and notify immediately
                        await MainActor.run {
                            storage.updateCachedBits(with: bits)
                            onBatchReady(storage.cachedBits)
                        }
                        successCount += 1
                    }
                case .failure:
                    continue
                }
            }

            // Mark first fetch complete
            if isFirstFetch && successCount > 0 {
                await MainActor.run {
                    storage.markFirstFetchComplete()
                }
            }
        }
    }

    /// Fetches a single RSS feed and converts to Bits
    private func fetchRSSFeed(feed: FeedConfig, isFirstFetch: Bool) async -> Result<[Bit], Error> {
        guard let url = URL(string: feed.url) else {
            return .failure(URLError(.badURL))
        }

        // Get last fetch time for this source (for delta fetching)
        let storage = await MainActor.run { StorageService.shared }
        let lastFetchTime = await MainActor.run { storage.getLastFetchTime(for: feed.source) }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return .failure(URLError(.badServerResponse))
            }

            let items = rssParser.parse(data: data)
            var bits = items.compactMap { item -> Bit? in
                guard !item.title.isEmpty else { return nil }

                let publishedAt = RSSParser.parseDate(item.pubDate)

                // For non-first fetches, only include items newer than last fetch
                if !isFirstFetch, let lastFetch = lastFetchTime {
                    if publishedAt <= lastFetch {
                        return nil
                    }
                }

                return Bit(
                    headline: item.title,
                    summary: item.description.isEmpty ? item.title : item.description,
                    category: feed.category,
                    source: feed.source,
                    publishedAt: publishedAt,
                    imageURL: item.imageURL.flatMap { URL(string: $0) },
                    articleURL: URL(string: item.link)
                )
            }

            // On first fetch, limit to 50 per source
            if isFirstFetch && bits.count > Self.itemsPerSourceFirstFetch {
                bits = Array(bits.prefix(Self.itemsPerSourceFirstFetch))
            }

            // Update last fetch time for this source
            await MainActor.run {
                storage.setLastFetchTime(Date(), for: feed.source)
            }

            return .success(bits)
        } catch {
            return .failure(error)
        }
    }

    /// Fetches bits for a specific category (from cache)
    func fetchBits(for category: BitCategory) async throws -> [Bit] {
        let allBits = try await fetchBits()
        return allBits.filter { $0.category == category }
    }

    /// Searches bits by keyword
    func searchBits(query: String) async throws -> [Bit] {
        let allBits = try await fetchBits()
        return allBits.filter { bit in
            bit.headline.localizedCaseInsensitiveContains(query) ||
            bit.summary.localizedCaseInsensitiveContains(query)
        }
    }

}
