import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: StorageService
    @StateObject private var viewModel = SettingsViewModel()

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
                            Text("\(Int(viewModel.maxArticlesValue))")
                                .foregroundColor(.gray)
                                .monospacedDigit()
                        }

                        Slider(
                            value: $viewModel.maxArticlesValue,
                            in: Double(AppConstants.minArticlesLimit)...Double(AppConstants.maxArticlesLimit),
                            step: 20
                        )
                        .tint(.orange)
                        .accessibilityLabel("Max cached bits")
                        .accessibilityValue("\(Int(viewModel.maxArticlesValue)) bits")
                        .onChange(of: viewModel.maxArticlesValue) { _, newValue in
                            viewModel.updateMaxArticles(newValue)
                        }

                        Text("Keep up to \(Int(viewModel.maxArticlesValue)) bits cached. Changes take effect on next refresh.")
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
                        viewModel.resetOnboarding()
                    }
                    .foregroundColor(.blue)
                    .accessibilityHint("Restarts the onboarding tutorial")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadSettings()
            }
        }
    }
}
