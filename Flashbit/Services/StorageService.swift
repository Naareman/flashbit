import Foundation

/// Manages persistent storage for saved articles and user preferences
class StorageService: ObservableObject {
    static let shared = StorageService()

    @Published var savedBits: [Bit] = []
    @Published var cachedBits: [Bit] = []
    @Published var selectedCategories: Set<BitCategory> = Set(BitCategory.allCases)
    @Published var hasCompletedOnboarding: Bool = false
    @Published var shouldNavigateToFeed: Bool = false
    @Published var showOnboardingComplete: Bool = false
    @Published var shouldNavigateToFeedAfterOnboarding: Bool = false

    // Track bits saved during current onboarding session
    private var onboardingSavedBitIds: Set<UUID> = []
    var isInOnboardingMode: Bool = false

    private let savedBitsKey = "savedBits"
    private let cachedBitsKey = "cachedBits"
    private let selectedCategoriesKey = "selectedCategories"
    private let onboardingKey = "hasCompletedOnboarding"
    private let lastFetchTimesKey = "lastFetchTimes"
    private let hasEverFetchedKey = "hasEverFetched"
    private let maxArticlesKey = "maxCachedArticles"
    private let seenBitIdsKey = "seenBitIds"

    // Track which articles the user has already seen
    private var seenBitIds: Set<String> = [] // Using articleURL string as identifier

    static let maxArticlesLimit = 500
    static let minArticlesLimit = 20
    static let defaultMaxArticles = 500

    @Published var maxCachedArticles: Int = 500

    init() {
        loadSavedBits()
        loadCachedBits()
        loadSelectedCategories()
        loadOnboardingStatus()
        loadMaxArticlesSetting()
        loadSeenBitIds()
    }

    private func loadOnboardingStatus() {
        // Check if key exists - if not, this is first launch
        if UserDefaults.standard.object(forKey: onboardingKey) == nil {
            hasCompletedOnboarding = false
            isInOnboardingMode = true
        } else {
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
            isInOnboardingMode = !hasCompletedOnboarding
        }
    }

    // MARK: - Saved Bits

    func saveBit(_ bit: Bit) {
        guard !isSaved(bit) else { return }
        savedBits.insert(bit, at: 0)
        persistSavedBits()

        // Track if saved during onboarding
        if isInOnboardingMode {
            onboardingSavedBitIds.insert(bit.id)
        }
    }

    func removeBit(_ bit: Bit) {
        savedBits.removeAll { $0.id == bit.id }
        onboardingSavedBitIds.remove(bit.id)
        persistSavedBits()
    }

    func isSaved(_ bit: Bit) -> Bool {
        savedBits.contains { $0.id == bit.id }
    }

    private func loadSavedBits() {
        guard let data = UserDefaults.standard.data(forKey: savedBitsKey),
              let bits = try? JSONDecoder().decode([Bit].self, from: data) else {
            return
        }
        savedBits = bits
    }

    private func persistSavedBits() {
        guard let data = try? JSONEncoder().encode(savedBits) else { return }
        UserDefaults.standard.set(data, forKey: savedBitsKey)
    }

    // MARK: - Selected Categories

    func toggleCategory(_ category: BitCategory) {
        if selectedCategories.contains(category) {
            // Don't allow deselecting all categories
            if selectedCategories.count > 1 {
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
        }
        persistSelectedCategories()
    }

    func isSelected(_ category: BitCategory) -> Bool {
        selectedCategories.contains(category)
    }

    private func loadSelectedCategories() {
        guard let data = UserDefaults.standard.data(forKey: selectedCategoriesKey),
              let categoryStrings = try? JSONDecoder().decode([String].self, from: data) else {
            // Default: all categories selected
            selectedCategories = Set(BitCategory.allCases)
            return
        }
        selectedCategories = Set(categoryStrings.compactMap { BitCategory(rawValue: $0) })
        if selectedCategories.isEmpty {
            selectedCategories = Set(BitCategory.allCases)
        }
    }

    private func persistSelectedCategories() {
        let categoryStrings = selectedCategories.map { $0.rawValue }
        guard let data = try? JSONEncoder().encode(categoryStrings) else { return }
        UserDefaults.standard.set(data, forKey: selectedCategoriesKey)
    }

    // MARK: - Onboarding

    func startOnboardingMode() {
        isInOnboardingMode = true
        onboardingSavedBitIds.removeAll()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        isInOnboardingMode = false
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    /// Clears only bits that were saved during the current onboarding session
    func clearOnboardingSavedBits() {
        savedBits.removeAll { onboardingSavedBitIds.contains($0.id) }
        onboardingSavedBitIds.removeAll()
        persistSavedBits()
    }

    func clearSavedBits() {
        savedBits = []
        onboardingSavedBitIds.removeAll()
        UserDefaults.standard.removeObject(forKey: savedBitsKey)
    }

    // For testing: reset onboarding
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: onboardingKey)
        startOnboardingMode()
        shouldNavigateToFeed = true
    }

    // MARK: - Cached Bits (Feed Cache)

    var isFirstFetch: Bool {
        !UserDefaults.standard.bool(forKey: hasEverFetchedKey)
    }

    func markFirstFetchComplete() {
        UserDefaults.standard.set(true, forKey: hasEverFetchedKey)
    }

    func updateCachedBits(with newBits: [Bit]) {
        // Merge new bits with existing, avoiding duplicates by articleURL
        var existingURLs = Set(cachedBits.compactMap { $0.articleURL?.absoluteString })
        var merged = cachedBits

        for bit in newBits {
            if let urlString = bit.articleURL?.absoluteString {
                if !existingURLs.contains(urlString) {
                    merged.append(bit)
                    existingURLs.insert(urlString)
                }
            } else {
                // No URL - check by headline to avoid duplicates
                if !merged.contains(where: { $0.headline == bit.headline && $0.source == bit.source }) {
                    merged.append(bit)
                }
            }
        }

        // Sort by date (newest first)
        merged.sort { $0.publishedAt > $1.publishedAt }

        // Keep only up to the user's max articles limit
        if merged.count > maxCachedArticles {
            merged = Array(merged.prefix(maxCachedArticles))
        }

        cachedBits = merged
        persistCachedBits()
    }

    func clearCachedBits() {
        cachedBits = []
        persistCachedBits()
    }

    private func loadCachedBits() {
        guard let data = UserDefaults.standard.data(forKey: cachedBitsKey),
              let bits = try? JSONDecoder().decode([Bit].self, from: data) else {
            return
        }
        cachedBits = bits
    }

    private func persistCachedBits() {
        guard let data = try? JSONEncoder().encode(cachedBits) else { return }
        UserDefaults.standard.set(data, forKey: cachedBitsKey)
    }

    // MARK: - Last Fetch Times (per source)

    func getLastFetchTime(for source: String) -> Date? {
        guard let data = UserDefaults.standard.data(forKey: lastFetchTimesKey),
              let times = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return nil
        }
        return times[source]
    }

    func setLastFetchTime(_ date: Date, for source: String) {
        var times: [String: Date] = [:]
        if let data = UserDefaults.standard.data(forKey: lastFetchTimesKey),
           let existing = try? JSONDecoder().decode([String: Date].self, from: data) {
            times = existing
        }
        times[source] = date
        if let data = try? JSONEncoder().encode(times) {
            UserDefaults.standard.set(data, forKey: lastFetchTimesKey)
        }
    }

    // MARK: - Max Articles Setting

    private func loadMaxArticlesSetting() {
        let saved = UserDefaults.standard.integer(forKey: maxArticlesKey)
        if saved > 0 {
            maxCachedArticles = min(saved, Self.maxArticlesLimit)
        } else {
            maxCachedArticles = Self.defaultMaxArticles
        }
    }

    func setMaxArticles(_ count: Int) {
        // Clamp between min and max limits
        let clamped = max(Self.minArticlesLimit, min(count, Self.maxArticlesLimit))
        maxCachedArticles = clamped
        UserDefaults.standard.set(clamped, forKey: maxArticlesKey)

        // If current cache exceeds new limit, trim it
        if cachedBits.count > clamped {
            cachedBits = Array(cachedBits.prefix(clamped))
            persistCachedBits()
        }
    }

    // MARK: - Seen Tracking

    /// Returns only the bits that the user hasn't seen yet
    func getUnseenBits() -> [Bit] {
        cachedBits.filter { !isSeen($0) }
    }

    /// Mark a bit as seen by the user
    func markAsSeen(_ bit: Bit) {
        let identifier = bitIdentifier(for: bit)
        guard !seenBitIds.contains(identifier) else { return }
        seenBitIds.insert(identifier)
        persistSeenBitIds()
    }

    /// Check if user has already seen this bit
    func isSeen(_ bit: Bit) -> Bool {
        seenBitIds.contains(bitIdentifier(for: bit))
    }

    /// Clear all seen tracking (for testing/reset)
    func clearSeenBits() {
        seenBitIds.removeAll()
        persistSeenBitIds()
    }

    private func bitIdentifier(for bit: Bit) -> String {
        // Use articleURL as primary identifier, fallback to headline+source
        if let url = bit.articleURL?.absoluteString {
            return url
        }
        return "\(bit.headline)|\(bit.source)"
    }

    private func loadSeenBitIds() {
        guard let data = UserDefaults.standard.data(forKey: seenBitIdsKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }
        seenBitIds = ids
    }

    private func persistSeenBitIds() {
        guard let data = try? JSONEncoder().encode(seenBitIds) else { return }
        UserDefaults.standard.set(data, forKey: seenBitIdsKey)
    }
}
