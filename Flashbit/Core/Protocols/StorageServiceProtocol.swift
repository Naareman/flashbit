import Foundation

protocol StorageServiceProtocol: ObservableObject {
    var savedBits: [Bit] { get }
    var cachedBits: [Bit] { get }
    var selectedCategories: Set<BitCategory> { get }
    var hasCompletedOnboarding: Bool { get set }
    var shouldNavigateToFeed: Bool { get set }
    var showOnboardingComplete: Bool { get set }
    var maxCachedArticles: Int { get }
    var isFirstFetch: Bool { get }
    var isInOnboardingMode: Bool { get set }

    func saveBit(_ bit: Bit)
    func removeBit(_ bit: Bit)
    func isSaved(_ bit: Bit) -> Bool
    func toggleCategory(_ category: BitCategory)
    func isSelected(_ category: BitCategory) -> Bool
    func completeOnboarding()
    func resetOnboarding()
    func clearOnboardingSavedBits()
    func updateCachedBits(with newBits: [Bit])
    func markFirstFetchComplete()
    func getLastFetchTime(for source: String) -> Date?
    func setLastFetchTime(_ date: Date, for source: String)
    func setMaxArticles(_ count: Int)
    func markAsSeen(_ bit: Bit)
    func isSeen(_ bit: Bit) -> Bool
}
