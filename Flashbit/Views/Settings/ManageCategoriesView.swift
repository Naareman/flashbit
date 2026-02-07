import SwiftUI

struct ManageCategoriesView: View {
    @EnvironmentObject private var storage: StorageService

    var body: some View {
        List {
            Section {
                Text("Select the categories you want to see in your bits")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Select the categories you want to see in your bits")
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
