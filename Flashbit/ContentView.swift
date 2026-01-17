import SwiftUI

struct ContentView: View {
    @ObservedObject private var storage = StorageService.shared
    @State private var selectedTab: Tab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeableFeedView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Bits", systemImage: "bolt.fill")
                }
                .tag(Tab.feed)

            BookmarksView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(Tab.saved)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.white)
        .onChange(of: storage.shouldNavigateToFeed) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = .feed
                storage.shouldNavigateToFeed = false
            }
        }
    }
}

enum Tab {
    case feed, saved, settings
}

// MARK: - Bookmarks View

struct BookmarksView: View {
    @Binding var selectedTab: Tab
    @ObservedObject private var storage = StorageService.shared
    @State private var showSuccessToast: Bool = false

    // Filter states
    @State private var selectedCategory: BitCategory? = nil
    @State private var sortNewestFirst: Bool = true
    @State private var showFilters: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var filterByDate: Bool = false

    // Filtered and sorted bits
    private var filteredBits: [Bit] {
        var bits = storage.savedBits

        // Filter by category
        if let category = selectedCategory {
            bits = bits.filter { $0.category == category }
        }

        // Filter by date range
        if filterByDate {
            bits = bits.filter { $0.publishedAt >= startDate && $0.publishedAt <= endDate }
        }

        // Sort
        if sortNewestFirst {
            bits.sort { $0.publishedAt > $1.publishedAt }
        } else {
            bits.sort { $0.publishedAt < $1.publishedAt }
        }

        return bits
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if storage.savedBits.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            // Filter bar
                            filterBar
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.black)

                            // Expanded filters
                            if showFilters {
                                expandedFilters
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                    .background(Color.black)
                            }

                            // Saved list
                            if filteredBits.isEmpty {
                                noResultsView
                            } else {
                                savedList
                            }
                        }
                    }
                }
                .background(Color.black)

                // "You're all set!" prominent overlay
                if showSuccessToast {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)

                        Text("You're all set!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showSuccessToast ? 1.0 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccessToast)
                }
            }
            .navigationTitle("Saved")
        }
        .onAppear {
            if storage.showOnboardingComplete {
                storage.showOnboardingComplete = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        showSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessToast = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            storage.clearOnboardingSavedBits()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = .feed
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack {
            // Filter toggle button
            Button(action: {
                withAnimation {
                    showFilters.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filter")
                }
                .font(.subheadline)
                .foregroundColor(hasActiveFilters ? .blue : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(hasActiveFilters ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // Sort toggle
            Button(action: {
                withAnimation {
                    sortNewestFirst.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
                    Text(sortNewestFirst ? "Newest" : "Oldest")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            // Results count
            Text("\(filteredBits.count) saved")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 8)
        }
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || filterByDate
    }

    // MARK: - Expanded Filters

    private var expandedFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All categories option
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )

                        ForEach(BitCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
            }

            // Date range filter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Date Range")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Toggle("", isOn: $filterByDate)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }

                if filterByDate {
                    HStack {
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()

                        Text("to")
                            .foregroundColor(.white.opacity(0.6))

                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .font(.caption)
                }
            }

            // Clear filters button
            if hasActiveFilters {
                Button(action: {
                    selectedCategory = nil
                    filterByDate = false
                }) {
                    Text("Clear all filters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No saved bits yet")
                .font(.title3)
                .foregroundColor(.white)

            Text("Double tap any bit to save it")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No matching bits")
                .font(.title3)
                .foregroundColor(.white)

            Text("Try adjusting your filters")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button("Clear filters") {
                selectedCategory = nil
                filterByDate = false
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBits) { bit in
                    SavedBitCard(bit: bit)
                }
            }
            .padding()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.white.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

struct SavedBitCard: View {
    let bit: Bit
    @ObservedObject private var storage = StorageService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            Text(bit.category.rawValue.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())

            // Headline
            Text(bit.headline)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)

            // Summary
            Text(bit.smartSummary)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)

            // Source and remove button
            HStack {
                Text(bit.source)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button(action: {
                    withAnimation {
                        storage.removeBit(bit)
                    }
                }) {
                    Image(systemName: "bookmark.slash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var storage = StorageService.shared
    @State private var maxArticlesValue: Double = 500

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    NavigationLink {
                        ManageCategoriesView()
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                            Text("Categories you want to see")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.orange)
                            Text("Max cached bits")
                            Spacer()
                            Text("\(Int(maxArticlesValue))")
                                .foregroundColor(.gray)
                                .monospacedDigit()
                        }

                        Slider(
                            value: $maxArticlesValue,
                            in: Double(StorageService.minArticlesLimit)...Double(StorageService.maxArticlesLimit),
                            step: 20
                        )
                        .tint(.orange)
                        .onChange(of: maxArticlesValue) { _, newValue in
                            storage.setMaxArticles(Int(newValue))
                        }

                        Text("Keep up to \(Int(maxArticlesValue)) bits cached. Changes take effect on next refresh.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Storage")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button("Show me how it works") {
                        storage.resetOnboarding()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                maxArticlesValue = Double(storage.maxCachedArticles)
            }
        }
    }
}

// MARK: - Manage Categories View

struct ManageCategoriesView: View {
    @ObservedObject private var storage = StorageService.shared

    var body: some View {
        List {
            Section {
                Text("Select the categories you want to see in your bits")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Section("Categories") {
                ForEach(BitCategory.allCases, id: \.self) { category in
                    CategoryToggleRow(category: category)
                }
            }
        }
        .navigationTitle("Categories")
    }
}

struct CategoryToggleRow: View {
    let category: BitCategory
    @ObservedObject private var storage = StorageService.shared

    var body: some View {
        Button(action: {
            storage.toggleCategory(category)
        }) {
            HStack {
                // Category icon
                Image(systemName: iconName(for: category))
                    .foregroundColor(colorFor(category))
                    .frame(width: 30)

                Text(category.rawValue)
                    .foregroundColor(.primary)

                Spacer()

                // Checkmark
                if storage.isSelected(category) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func iconName(for category: BitCategory) -> String {
        switch category {
        case .breaking: return "exclamationmark.triangle.fill"
        case .tech: return "cpu.fill"
        case .business: return "chart.line.uptrend.xyaxis"
        case .sports: return "sportscourt.fill"
        case .entertainment: return "film.fill"
        case .science: return "atom"
        case .health: return "heart.fill"
        case .world: return "globe"
        }
    }

    private func colorFor(_ category: BitCategory) -> Color {
        switch category {
        case .breaking: return .red
        case .tech: return .blue
        case .business: return .green
        case .sports: return .orange
        case .entertainment: return .purple
        case .science: return .cyan
        case .health: return .pink
        case .world: return .indigo
        }
    }
}

#Preview {
    ContentView()
}
