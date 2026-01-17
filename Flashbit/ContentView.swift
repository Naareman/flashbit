import SwiftUI

struct ContentView: View {
    @ObservedObject private var storage = StorageService.shared
    @State private var selectedTab: Tab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeableFeedView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Feed", systemImage: "bolt.fill")
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

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if storage.savedBits.isEmpty {
                        emptyState
                    } else {
                        savedList
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
                // Longer delay before showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        showSuccessToast = true
                    }
                    // Hide after showing and navigate to Feed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessToast = false
                        }
                        // Clear saved bits from onboarding, then navigate to Feed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            storage.clearSavedBits()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = .feed
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No saved bits yet")
                .font(.title3)
                .foregroundColor(.white)

            Text("Double-tap any story to save it")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(storage.savedBits) { bit in
                    SavedBitCard(bit: bit)
                }
            }
            .padding()
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
            Text(bit.summary)
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
                            Text("Manage Categories")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.orange)
                            Text("Max Cached Articles")
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

                        Text("Keep up to \(Int(maxArticlesValue)) articles cached for offline reading. Older articles will be removed when the limit is reached.")
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
                    Button("Show Onboarding Again") {
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
                Text("Select the categories you want to see in your feed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Section("Categories") {
                ForEach(BitCategory.allCases, id: \.self) { category in
                    CategoryToggleRow(category: category)
                }
            }
        }
        .navigationTitle("Manage Categories")
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
