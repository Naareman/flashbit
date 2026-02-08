import Foundation

@MainActor
class SavedViewModel: ObservableObject {
    @Published var selectedCategory: BitCategory? = nil
    @Published var sortNewestFirst: Bool = true
    @Published var showFilters: Bool = false
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var filterByDate: Bool = false

    private let storage: StorageService

    init(storage: StorageService? = nil) {
        self.storage = storage ?? .shared
    }

    var filteredBits: [Bit] {
        var bits = storage.savedBits

        if let category = selectedCategory {
            bits = bits.filter { $0.category == category }
        }

        if filterByDate {
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            bits = bits.filter { $0.publishedAt >= dayStart && $0.publishedAt < dayEnd }
        }

        if sortNewestFirst {
            bits.sort { $0.publishedAt > $1.publishedAt }
        } else {
            bits.sort { $0.publishedAt < $1.publishedAt }
        }

        return bits
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil || filterByDate
    }

    func clearFilters() {
        selectedCategory = nil
        filterByDate = false
    }

    func toggleFilters() {
        showFilters.toggle()
    }

    func toggleSort() {
        sortNewestFirst.toggle()
    }
}
