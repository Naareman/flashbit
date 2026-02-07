import SwiftUI

struct CategoryToggleRow: View {
    let category: BitCategory
    @ObservedObject private var storage = StorageService.shared

    var body: some View {
        Button(action: {
            storage.toggleCategory(category)
        }) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .frame(width: 30)

                Text(category.rawValue)
                    .foregroundColor(.primary)

                Spacer()

                if storage.isSelected(category) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
