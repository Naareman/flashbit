import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var maxArticlesValue: Double = 500

    private let storage: StorageService
    private var sliderDebounceTask: Task<Void, Never>?

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadSettings() {
        maxArticlesValue = Double(storage.maxCachedArticles)
    }

    func updateMaxArticles(_ newValue: Double) {
        // Debounce slider changes to avoid excessive UserDefaults writes
        sliderDebounceTask?.cancel()
        sliderDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            storage.setMaxArticles(Int(newValue))
        }
    }

    func resetOnboarding() {
        storage.resetOnboarding()
    }
}
