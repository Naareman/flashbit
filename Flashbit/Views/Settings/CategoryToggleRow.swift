import SwiftUI

struct CategoryToggleRow: View {
    let category: BitCategory
    @EnvironmentObject private var storage: StorageService

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
        .accessibilityLabel("\(category.rawValue)")
        .accessibilityValue(storage.isSelected(category) ? "Enabled" : "Disabled")
        .accessibilityHint("Toggles \(category.rawValue) category")
    }
}
