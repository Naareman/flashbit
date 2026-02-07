import SwiftUI

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
