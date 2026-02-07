import SwiftUI

struct BookmarksView: View {
    @Binding var selectedTab: Tab
    @ObservedObject private var storage = StorageService.shared
    @StateObject private var viewModel = SavedViewModel()
    @State private var showSuccessToast: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if storage.savedBits.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            filterBar
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.black)

                            if viewModel.showFilters {
                                expandedFilters
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                    .background(Color.black)
                            }

                            if viewModel.filteredBits.isEmpty {
                                noResultsView
                            } else {
                                savedList
                            }
                        }
                    }
                }
                .background(Color.black)

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
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.successToastDelay) {
                    withAnimation {
                        showSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.successToastDuration) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessToast = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.clearOnboardingDelay) {
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
            Button(action: {
                withAnimation {
                    viewModel.toggleFilters()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filter")
                }
                .font(.subheadline)
                .foregroundColor(viewModel.hasActiveFilters ? .blue : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.hasActiveFilters ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    viewModel.toggleSort()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.sortNewestFirst ? "arrow.down" : "arrow.up")
                    Text(viewModel.sortNewestFirst ? "Newest" : "Oldest")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }

            Text("\(viewModel.filteredBits.count) saved")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 8)
        }
    }

    // MARK: - Expanded Filters

    private var expandedFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil,
                            action: { viewModel.selectedCategory = nil }
                        )

                        ForEach(BitCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category,
                                action: { viewModel.selectedCategory = category }
                            )
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Date Range")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Toggle("", isOn: $viewModel.filterByDate)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }

                if viewModel.filterByDate {
                    HStack {
                        DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()

                        Text("to")
                            .foregroundColor(.white.opacity(0.6))

                        DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .font(.caption)
                }
            }

            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearFilters()
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

    // MARK: - Subviews

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
                viewModel.clearFilters()
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredBits) { bit in
                    SavedBitCard(bit: bit)
                }
            }
            .padding()
        }
    }
}
