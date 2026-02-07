import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var maxArticlesValue: Double = 500

    private let storage: StorageService

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadSettings() {
        maxArticlesValue = Double(storage.maxCachedArticles)
    }

    func updateMaxArticles(_ newValue: Double) {
        storage.setMaxArticles(Int(newValue))
    }

    func resetOnboarding() {
        storage.resetOnboarding()
    }
}
